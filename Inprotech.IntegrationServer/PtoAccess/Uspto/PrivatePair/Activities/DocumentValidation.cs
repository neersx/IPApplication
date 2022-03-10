using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IDocumentValidation
    {
        Task<bool> MarkIfAlreadyProcessed(ApplicationDownload application, LinkInfo pdfLink);
    }

    class DocumentValidation : IDocumentValidation
    {
        readonly IRepository _repository;
        readonly IBiblioStorage _biblioStorage;
        readonly IFileNameExtractor _fileNameExtractor;
        readonly IFileSystem _fileSystem;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public DocumentValidation(IRepository repository, IBiblioStorage biblioStorage, IFileNameExtractor fileNameExtractor, IFileSystem fileSystem, IScheduleRuntimeEvents scheduleRuntimeEvents)
        {
            _repository = repository;
            _biblioStorage = biblioStorage;
            _fileNameExtractor = fileNameExtractor;
            _fileSystem = fileSystem;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
        }

        public async Task<bool> MarkIfAlreadyProcessed(ApplicationDownload application, LinkInfo pdfLink)
        {
            if (pdfLink.LinkType != LinkTypes.Pdf)
                return false;

            var biblioData = await _biblioStorage.Read(application);
            var documentName = _fileNameExtractor.AbsoluteUriName(pdfLink.Link);
            var fileWrapper = biblioData.ImageFileWrappers.First(_ => _.FileName == documentName);
            var doc = fileWrapper.ToAvailableDocument();

            var document = _repository.Set<Document>()
                                      .Include(_ => _.FileStore)
                                      .SingleOrDefault(e => (e.DocumentObjectId == doc.ObjectId || e.DocumentObjectId == doc.FileNameObjectId)
                                                            && e.Source == DataSourceType.UsptoPrivatePair
                                                            && e.ApplicationNumber == application.Number
                                                            && e.MailRoomDate == doc.MailRoomDate);

            var alreadyProcessed = document != null && !new[] { DocumentDownloadStatus.Failed, DocumentDownloadStatus.Pending }.Contains(document.Status)
                                    && document.FileStore != null
                                    && _fileSystem.Exists(_fileSystem.AbsolutePath(document.FileStore.Path));
            if (alreadyProcessed)
                _scheduleRuntimeEvents.DocumentProcessed(application.SessionId, document);

            return alreadyProcessed;
        }
    }
}