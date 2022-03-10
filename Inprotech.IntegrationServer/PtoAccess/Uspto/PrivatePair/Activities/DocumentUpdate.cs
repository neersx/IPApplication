using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.AutomaticDocketing;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IDocumentUpdate
    {
        Task Apply(Session session, ApplicationDownload applicationDownload, AvailableDocument availableDocument);
    }

    public class DocumentUpdate : IDocumentUpdate
    {
        readonly IRepository _repository;
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly Func<DateTime> _now;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;
        readonly ICalculateDownloadStatus _statusCalculator;

        public DocumentUpdate(IRepository repository, IArtifactsLocationResolver artifactsLocationResolver,
            Func<DateTime> now, IScheduleRuntimeEvents scheduleRuntimeEvents, ICalculateDownloadStatus statusCalculator)
        {
            _repository = repository;
            _artifactsLocationResolver = artifactsLocationResolver;
            _now = now;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _statusCalculator = statusCalculator;
        }

        public async Task Apply(Session session, ApplicationDownload applicationDownload,
            AvailableDocument availableDocument)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (applicationDownload == null) throw new ArgumentNullException(nameof(applicationDownload));
            if (availableDocument == null) throw new ArgumentNullException(nameof(availableDocument));

            var doc = await CreateOrUpdateDocumentStatus(applicationDownload, availableDocument);

            _scheduleRuntimeEvents.DocumentProcessed(applicationDownload.SessionId, doc);
        }

        async Task<Document> CreateOrUpdateDocumentStatus(ApplicationDownload applicationDownload, AvailableDocument availableDocument)
        {
            var now = _now();
            var u = GetOrCreateFor(applicationDownload.Number, availableDocument, out bool existing);
            u.UpdatedOn = now;
            u.DocumentCategory = availableDocument.DocumentCategory;
            u.DocumentDescription = availableDocument.DocumentDescription;
            u.FileWrapperDocumentCode = availableDocument.FileWrapperDocumentCode;
            u.PageCount = availableDocument.PageCount;
            u.MailRoomDate = availableDocument.MailRoomDate;
            u.Errors = null;

            if (existing && (u.Status == DocumentDownloadStatus.Failed || u.Status == DocumentDownloadStatus.Pending) || !existing)
            {
                u.Status = _statusCalculator.GetDownloadStatus(DataSourceType.UsptoPrivatePair);
            }

            var fileName = availableDocument.FileNameObjectId;
            if (!fileName.EndsWith(".pdf"))
                fileName += ".pdf";
            u.FileStore = new FileStore
            {
                OriginalFileName = fileName,
                Path = _artifactsLocationResolver.ResolveFiles(applicationDownload, fileName)
            };

            if (u.DocumentEvent == null)
            {
                u.DocumentEvent = new DocumentEvent(u)
                {
                    CreatedOn = now,
                    UpdatedOn = now,
                    Status = DocumentEventStatus.Pending
                };
            }

            await _repository.SaveChangesAsync();

            return u;
        }

        Document GetOrCreateFor(string applicationNumber, AvailableDocument doc, out bool existing)
        {
            var u = _repository.Set<Document>()
                .Include(_ => _.DocumentEvent)
                .SingleOrDefault(e => (e.DocumentObjectId == doc.ObjectId || e.DocumentObjectId == doc.FileNameObjectId)
                                    && e.Source == DataSourceType.UsptoPrivatePair
                                    && e.ApplicationNumber == applicationNumber);

            existing = u != null;

            return u ?? _repository.Set<Document>().Add(
                new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = applicationNumber,
                    DocumentObjectId = doc.ObjectId,
                    MailRoomDate = doc.MailRoomDate,
                    CreatedOn = _now(),
                    UpdatedOn = _now(),
                    Status = _statusCalculator.GetDownloadStatus(DataSourceType.UsptoPrivatePair),
                    Reference = Guid.NewGuid()
                });
        }
    }
}