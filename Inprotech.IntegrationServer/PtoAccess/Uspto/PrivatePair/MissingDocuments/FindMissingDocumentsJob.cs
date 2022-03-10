using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MissingDocuments
{
    public class FindMissingDocumentsJob : IPerformBackgroundJob
    {
        readonly IRepository _repository;
        readonly IFileSystem _fileSystem;
        readonly IBufferedStringReader _bufferedStringReader;

        public FindMissingDocumentsJob(IRepository repository, IFileSystem fileSystem, IBufferedStringReader bufferedStringReader)
        {
            _repository = repository;
            _fileSystem = fileSystem;
            _bufferedStringReader = bufferedStringReader;
        }

        public string Type => nameof(FindMissingDocumentsJob);

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<FindMissingDocumentsJob>(_ => _.Discover());
        }

        public async Task<Activity> Discover()
        {
            var biblioFileStores = await (from c in _repository.Set<Case>().Where(_ => _.Source == DataSourceType.UsptoPrivatePair)
                                          join cf in _repository.Set<CaseFiles>() on new { CaseId = c.Id, Type = (int)CaseFileType.Biblio } equals new { cf.CaseId, cf.Type }
                                          select new
                                          {
                                              CaseId = c.Id,
                                              c.ApplicationNumber,
                                              cf.FileStore
                                          }).ToArrayAsync();

            var missingDocs = new List<AvailableDocument>();

            foreach (var bFileStore in biblioFileStores)
            {
                if (_fileSystem.Exists(_fileSystem.AbsolutePath(bFileStore.FileStore.Path)))
                {
                    var missing = await CheckApplication(bFileStore.ApplicationNumber, bFileStore.FileStore.Path);
                    if (missing.Any())
                    {
                        missingDocs.AddRange(missing);
                    }
                }
            }

            if (missingDocs.Any())
            {
                _fileSystem.WriteAllText($"UsptoIntegration-MissingDocs\\{DateTime.Now:yyyy-MM-dd}.txt", JsonConvert.SerializeObject(missingDocs));
            }

            return DefaultActivity.NoOperation();
        }

        async Task<List<AvailableDocument>> CheckApplication(string applicationNumber, string biblioPath)
        {
            var biblio = await Read(biblioPath);
            var documents = await _repository.Set<Document>().Where(_ => _.ApplicationNumber == applicationNumber).ToArrayAsync();
            var minMailRoomDate = documents.Select(_ => _.MailRoomDate).Min();
            var missingDocs = new List<AvailableDocument>();
            foreach (var wrapper in biblio.ImageFileWrappers.Where(_ => _.MailDateParsed >= minMailRoomDate))
            {
                var doc = wrapper.ToAvailableDocument();
                var existing = documents.SingleOrDefault(e => e.DocumentObjectId == doc.ObjectId || e.DocumentObjectId == doc.FileNameObjectId
                                                           && e.Source == DataSourceType.UsptoPrivatePair
                                                           && e.ApplicationNumber == wrapper.AppId
                                                           && e.MailRoomDate == doc.MailRoomDate);

                if (existing == null && ValidDocCodes.DocCodes.Contains(doc.FileWrapperDocumentCode))
                {
                    missingDocs.Add(doc);
                }
            }

            return missingDocs;
        }

        async Task<BiblioFile> Read(string biblioPath)
        {
            var content = await _bufferedStringReader.Read(biblioPath);
            return JsonConvert.DeserializeObject<BiblioFile>(content);
        }
    }
}