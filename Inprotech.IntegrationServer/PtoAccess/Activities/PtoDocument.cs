using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.AutomaticDocketing;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public interface IPtoDocument
    {
        Task Download(DataDownload dataDownload, Document document,
                      Func<string, string, string, string, string, string, Task> downloadDocumentAsync);
    }

    public class PtoDocument : IPtoDocument
    {
        readonly IRepository _repository;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;
        readonly ICalculateDownloadStatus _downloadStatusCalculator;
        readonly Func<DateTime> _now;

        public PtoDocument(IRepository repository, IDataDownloadLocationResolver dataDownloadLocationResolver,
                           IScheduleRuntimeEvents scheduleRuntimeEvents,
                           Func<DateTime> now, ICalculateDownloadStatus downloadStatusCalculator)
        {
            _repository = repository;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _now = now;
            _downloadStatusCalculator = downloadStatusCalculator;
        }

        public async Task Download(DataDownload dataDownload, Document document,
                                   Func<string, string, string, string, string, string, Task> downloadDocumentAsync)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));
            if (document == null) throw new ArgumentNullException(nameof(document));
            if (downloadDocumentAsync == null) throw new ArgumentNullException(nameof(downloadDocumentAsync));

            var fileName = document.DocumentObjectId + document.FileExtension();
            var filePath = _dataDownloadLocationResolver.Resolve(dataDownload, fileName);

            await downloadDocumentAsync(document.ApplicationNumber,
                                        document.DocumentObjectId,
                                        document.DocumentDescription,
                                        document.MediaType,
                                        document.SourceUrl,
                                        filePath);

            var now = _now();
            var doc = _repository.Set<Document>()
                                 .For(dataDownload)
                                 .Include(_ => _.DocumentEvent)
                                 .SingleOrDefault(_ => _.DocumentObjectId == document.DocumentObjectId && _.Source == document.Source);

            var existing = doc != null;

            if (!existing)
            {
                doc = _repository.Set<Document>().Add(
                                                      new Document
                                                      {
                                                          Source = dataDownload.DataSourceType,
                                                          DocumentObjectId = document.DocumentObjectId,
                                                          ApplicationNumber = document.ApplicationNumber,
                                                          RegistrationNumber = document.RegistrationNumber,
                                                          PublicationNumber = document.PublicationNumber,
                                                          MailRoomDate = document.MailRoomDate,
                                                          PageCount = document.PageCount,
                                                          DocumentCategory = document.DocumentCategory,
                                                          DocumentDescription = document.DocumentDescription,
                                                          SourceUrl = document.SourceUrl,
                                                          Reference = Guid.NewGuid(),
                                                          CreatedOn = now
                                                      });
            }

            if (existing && (doc.Status == DocumentDownloadStatus.Failed || doc.Status == DocumentDownloadStatus.Pending) || !existing)
            {
                doc.Status = _downloadStatusCalculator.GetDownloadStatus(dataDownload.DataSourceType);
            }

            doc.Errors = null;
            doc.UpdatedOn = now;
            doc.MediaType = document.MediaType;
            doc.SourceUrl = document.SourceUrl;
            doc.FileStore = new FileStore
                            {
                                OriginalFileName = fileName,
                                Path = filePath
                            };

            if (doc.DocumentEvent == null)
            {
                doc.DocumentEvent = new DocumentEvent(doc)
                                    {
                                        CreatedOn = now,
                                        UpdatedOn = now,
                                        Status = DocumentEventStatus.Pending
                                    };
            }

            await _repository.SaveChangesAsync();

            _scheduleRuntimeEvents.DocumentProcessed(dataDownload.Id, doc);
        }
    }
}