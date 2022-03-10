using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Storage;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IBiblioStorage
    {
        Task<(FileStore fileStore, DateTime date)> GetFileStoreBiblioInfo(string applicationId);

        Task StoreBiblio(ApplicationDownload applicationDownload, DateTime messageTimeStamp);

        Task ValidateBiblio(Session session, ApplicationDownload applicationDownload);

        Task<BiblioFile> Read(ApplicationDownload application);
    }

    internal class BiblioStorage : IBiblioStorage
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IBufferedStringReader _bufferedStringReader;
        readonly ICorrelationIdUpdator _correlationIdUpdator;
        readonly IFileSystem _fileSystem;
        readonly Func<DateTime> _now;
        readonly IRepository _repository;

        public BiblioStorage(IRepository repository, IArtifactsLocationResolver artifactsLocationResolver, IFileSystem fileSystem, ICorrelationIdUpdator correlationIdUpdator,
                             IBufferedStringReader bufferedStringReader, Func<DateTime> now)
        {
            _repository = repository;
            _artifactsLocationResolver = artifactsLocationResolver;
            _fileSystem = fileSystem;
            _correlationIdUpdator = correlationIdUpdator;
            _bufferedStringReader = bufferedStringReader;
            _now = now;
        }

        public async Task<(FileStore fileStore, DateTime date)> GetFileStoreBiblioInfo(string applicationId)
        {
            var fileStore = await (from c in _repository.Set<Case>().Where(_ => _.Source == DataSourceType.UsptoPrivatePair &&
                                                                                _.ApplicationNumber == applicationId)
                                   join cf in _repository.Set<CaseFiles>() on new { CaseId = c.Id, Type = (int)CaseFileType.Biblio } equals new { cf.CaseId, cf.Type }
                                   orderby cf.Id descending
                                   select new { cf.FileStore, cf.UpdatedOn }).FirstOrDefaultAsync();

            return (fileStore?.FileStore, fileStore?.UpdatedOn ?? DateTime.MinValue);
        }

        public async Task StoreBiblio(ApplicationDownload applicationDownload, DateTime messageTimeStamp)
        {
            var caseId = await EnsureCaseAvailable(applicationDownload.Number);
            await EnsureCaseFileAvailable(applicationDownload, caseId, messageTimeStamp);
        }

        public async Task ValidateBiblio(Session session, ApplicationDownload applicationDownload)
        {
            var fileStore = await GetFileStoreBiblioInfo(applicationDownload.ApplicationId);
            if (fileStore.fileStore == null || !_fileSystem.Exists(_fileSystem.AbsolutePath(fileStore.fileStore.Path)))
            {
                throw new Exception($"Unable to find Biblio file for Session:{session.ScheduleId}---Customer Number:{applicationDownload.CustomerNumber}---Application:{applicationDownload.ApplicationId}");
            }
        }

        public async Task<BiblioFile> Read(ApplicationDownload application)
        {
            var biblioInfo = await GetFileStoreBiblioInfo(application.ApplicationId);
            if (biblioInfo.fileStore == null)
            {
                return await Read(_artifactsLocationResolver.ResolveBiblio(application));
            }

            return await Read(biblioInfo.fileStore.Path);
        }

        async Task<BiblioFile> Read(string biblioPath)
        {
            var content = await _bufferedStringReader.Read(biblioPath);
            return JsonConvert.DeserializeObject<BiblioFile>(content);
        }

        async Task<int> EnsureCaseAvailable(string applicationNumber)
        {
            var cases = _repository.Set<Case>();
            var @case = cases.SingleOrDefault(n => n.Source == DataSourceType.UsptoPrivatePair &&
                                                   n.ApplicationNumber == applicationNumber) ??
                        cases.Add(
                                  new Case
                                  {
                                      ApplicationNumber = applicationNumber,
                                      Source = DataSourceType.UsptoPrivatePair,
                                      CreatedOn = _now(),
                                      UpdatedOn = _now()
                                  });
            await _repository.SaveChangesAsync();
            _correlationIdUpdator.UpdateIfRequired(@case);
            return @case.Id;
        }

        async Task EnsureCaseFileAvailable(ApplicationDownload applicationDownload, int caseId, DateTime messageTimeStamp)
        {
            var fileStore = new FileStore
            {
                Path = _artifactsLocationResolver.ResolveBiblio(applicationDownload),
                OriginalFileName = $"biblio_{applicationDownload.ApplicationId}"
            };
            var caseFiles = _repository.Set<CaseFiles>();
            var caseFile = await caseFiles.Include(x => x.FileStore).OrderByDescending(_ => _.Id).FirstOrDefaultAsync(_ => _.CaseId == caseId && _.Type == (int)CaseFileType.Biblio);
            if (caseFile == null)
            {
                caseFiles.Add(new CaseFiles
                {
                    CaseId = caseId,
                    Type = (int)CaseFileType.Biblio,
                    FileStore = fileStore,
                    UpdatedOn = messageTimeStamp
                });
            }
            else
            {
                if (messageTimeStamp >= (caseFile.UpdatedOn ?? DateTime.MinValue))
                {
                    caseFile.FileStore.Path = fileStore.Path;
                    caseFile.FileStore.OriginalFileName = fileStore.OriginalFileName;
                    caseFile.UpdatedOn = messageTimeStamp;
                }
            }

            await _repository.SaveChangesAsync();
        }
    }
}