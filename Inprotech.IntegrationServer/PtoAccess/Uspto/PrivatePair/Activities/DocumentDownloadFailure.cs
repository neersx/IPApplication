using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IDocumentDownloadFailure
    {
        Task NotifyFailure(ApplicationDownload application, LinkInfo info, string messageFileName);
        Task NotifyBiblioFailure(ApplicationDownload application);
    }

    public class DocumentDownloadFailure : IDocumentDownloadFailure
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IArtifactsService _artifactsService;
        readonly IGlobErrors _exceptionGlobber;
        readonly IFileNameExtractor _fileNameExtractor;
        readonly IFileSystem _fileSystem;
        readonly IBufferedStringReader _bufferedStringReader;
        readonly Func<DateTime> _now;
        readonly IRepository _repository;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;
        readonly IBiblioStorage _biblioStorage;

        public DocumentDownloadFailure(IRepository repository, Func<DateTime> now,
                                       IGlobErrors exceptionGlobber,
                                       IArtifactsLocationResolver artifactsLocationResolver,
                                       IArtifactsService artifactsService,
                                       IScheduleRuntimeEvents scheduleRuntimeEvents,
                                       IBiblioStorage biblioStorage, IFileNameExtractor fileNameExtractor, IFileSystem fileSystem, IBufferedStringReader bufferedStringReader)
        {
            _repository = repository;
            _now = now;
            _exceptionGlobber = exceptionGlobber;
            _artifactsLocationResolver = artifactsLocationResolver;
            _artifactsService = artifactsService;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _biblioStorage = biblioStorage;
            _fileNameExtractor = fileNameExtractor;
            _fileSystem = fileSystem;
            _bufferedStringReader = bufferedStringReader;
        }

        public async Task NotifyFailure(ApplicationDownload application, LinkInfo info, string messageFileName)
        {
            var documentName = _fileNameExtractor.AbsoluteUriName(info.Link);
            var biblioData = await _biblioStorage.Read(application);
            var fileWrapper = biblioData.ImageFileWrappers.First(_ => _.FileName == documentName);

            await NotifyFailure(application, fileWrapper.ToAvailableDocument(), messageFileName);
        }

        public async Task NotifyBiblioFailure(ApplicationDownload application)
        {
            var applicationFolderLocation = _artifactsLocationResolver.Resolve(application);
            var error = JsonConvert.SerializeObject(await _exceptionGlobber.GlobFor(application));
            foreach (var messageFile in _fileSystem.Files(applicationFolderLocation, "*.json"))
            {
                var message = JsonConvert.DeserializeObject<Message>(await _bufferedStringReader.Read(messageFile));
                var info = message.Links.For(LinkTypes.Pdf);
                if (info?.Link != null)
                {
                    var documentName = _fileNameExtractor.AbsoluteUriName(info.Link);
                    var (mailRoomDate, docObjectId, docCode) = ExtractInformationFromDocumentName(documentName);

                    var availableDocument = new AvailableDocument()
                    {
                        ObjectId = docObjectId,
                        FileNameObjectId = documentName.EndsWith(".pdf")
                            ? documentName.Remove(documentName.LastIndexOf(".pdf", StringComparison.InvariantCultureIgnoreCase), 4)
                            : documentName,
                        MailRoomDate = mailRoomDate,
                        FileWrapperDocumentCode = docCode
                    };

                    await NotifyFailure(application, availableDocument, messageFile, error);
                }
            }
        }

        async Task NotifyFailure(ApplicationDownload application, AvailableDocument availableDocument, string messageFileName, string error = null)
        {
            if (application == null) throw new ArgumentNullException(nameof(application));
            if (availableDocument == null) throw new ArgumentNullException(nameof(availableDocument));

            var document = GetOrCreateFor(application.Number, availableDocument);
            document.Status = DocumentDownloadStatus.Failed;
            document.DocumentCategory = availableDocument.DocumentCategory;
            document.DocumentDescription = availableDocument.DocumentDescription;
            document.FileWrapperDocumentCode = availableDocument.FileWrapperDocumentCode;
            document.PageCount = availableDocument.PageCount;
            document.MailRoomDate = availableDocument.MailRoomDate;
            document.Errors = string.IsNullOrEmpty(error) ? JsonConvert.SerializeObject(await _exceptionGlobber.GlobFor(application, availableDocument)) : error;
            document.UpdatedOn = _now();
            await _repository.SaveChangesAsync();

            var location = _artifactsLocationResolver.Resolve(application);
            var artifacts = _artifactsService.CreateCompressedArchive(location, retainMessageNames: new[] { Path.GetFileName(messageFileName), $"biblio_{application.ApplicationId}", ".log" });

            _scheduleRuntimeEvents.DocumentFailed(application.SessionId, document, artifacts);
        }

        Document GetOrCreateFor(string applicationNumber, AvailableDocument doc)
        {
            var u = _repository.Set<Document>()
                               .SingleOrDefault(e => (e.DocumentObjectId == doc.ObjectId || e.DocumentObjectId == doc.FileNameObjectId)
                                                     && e.Source == DataSourceType.UsptoPrivatePair
                                                     && e.ApplicationNumber == applicationNumber);

            return u ?? _repository.Set<Document>().Add(
                                                        new Document
                                                        {
                                                            Source = DataSourceType.UsptoPrivatePair,
                                                            ApplicationNumber = applicationNumber,
                                                            DocumentObjectId = doc.ObjectId,
                                                            MailRoomDate = doc.MailRoomDate,
                                                            CreatedOn = _now(),
                                                            UpdatedOn = _now(),
                                                            Reference = Guid.NewGuid()
                                                        });
        }

        (DateTime mailRoomDate, string docObjectId, string docCode) ExtractInformationFromDocumentName(string fileName)
        {
            var matches = Regex.Match(fileName, @"(?<appId>\d*)-(?<mailRoomDate>\d{4}-\d{2}-\d{2})-(?<docObjectId>\w*)-(?<docCode>.*?).pdf");
            if (matches.Success)
            {
                return (DateTime.ParseExact(matches.Groups["mailRoomDate"].Value, "yyyy-MM-dd", null), matches.Groups["docObjectId"].Value, matches.Groups["docCode"].Value);
            }

            return (DateTime.MinValue, fileName, null);
        }
    }
}