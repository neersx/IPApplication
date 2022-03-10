using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.WorkflowIntegration;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.Activities
{
    public class DocumentList
    {
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly IEpRegisterClient _epRegisterClient;
        readonly IAllDocumentsTabExtractor _documentsTabExtractor;
        readonly IRepository _repository;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public DocumentList(IDataDownloadLocationResolver dataDownloadLocationResolver,
            IBufferedStringWriter bufferedStringWriter, IEpRegisterClient epRegisterClient,
            IAllDocumentsTabExtractor documentsTabExtractor, IRepository repository,
            IScheduleRuntimeEvents scheduleRuntimeEvents)
        {
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _bufferedStringWriter = bufferedStringWriter;
            _epRegisterClient = epRegisterClient;
            _documentsTabExtractor = documentsTabExtractor;
            _repository = repository;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
        }

        public async Task<Activity> For(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var newDocs = (await FindNewDocuments(dataDownload)).ToArray();

            _scheduleRuntimeEvents.IncludeDocumentsForCase(dataDownload.Id, newDocs.Length);

            return newDocs.Any()
                ? Activity.Sequence(DownloadDocuments(newDocs, dataDownload), AfterDownload(dataDownload))
                : AfterDownloadWithoutDocs(dataDownload);
        }

        async Task<IEnumerable<Document>> FindNewDocuments(DataDownload dataDownload)
        {
            if (string.IsNullOrEmpty(dataDownload.Case.ApplicationNumber)) throw new Exception("Application Number is required for EPO document download.");

            var content =
                await
                    _epRegisterClient.DownloadDocumentsList(dataDownload.Case.ApplicationNumber);
            var path = _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.DocumentList);

            await _bufferedStringWriter.Write(path, content);

            var found = _documentsTabExtractor.Extract(content).ToArray();

            var documentIds = found.Select(_ => _.DocumentId);

            var existingDocs = _repository.Set<Document>()
                .Where(_ => _.Status == DocumentDownloadStatus.Downloaded && documentIds.Contains(_.DocumentObjectId))
                .For(dataDownload)
                .Select(_ => _.DocumentObjectId);

            return DocumentsFrom(found.Where(_ => !existingDocs.Contains(_.DocumentId)), dataDownload);
        }

        static IEnumerable<Document> DocumentsFrom(IEnumerable<AvailableDocument> availableDocuments, DataDownload dataDownload)
        {
            return availableDocuments.
                Select(d => new Document
            {
                DocumentObjectId = d.DocumentId,
                ApplicationNumber = dataDownload.Case.ApplicationNumber ?? d.Number,
                RegistrationNumber = dataDownload.Case.RegistrationNumber,
                PublicationNumber = dataDownload.Case.PublicationNumber,
                MailRoomDate = d.Date,
                PageCount = d.NumberOfPages,
                DocumentCategory = d.Procedure,
                DocumentDescription = d.DocumentName,
                Source = DataSourceType.Epo
            });
        }

        static Activity DownloadDocuments(IEnumerable<Document> newDocs, DataDownload dataDownload)
        {
            return Activity.Sequence(
                newDocs.Select(_ =>
                    Activity.Run<DownloadDocument>(dd => dd.Download(dataDownload, _))
                        .ExceptionFilter<ErrorLogger>((ex, e) => e.LogContextError(ex, dataDownload, _.DocumentObjectId))
                        .Failed(Activity.Run<DownloadDocumentFailed>(d => d.NotifyFailure(dataDownload, _)))
                        .ThenContinue()));
        }

        static Activity AfterDownload(DataDownload dataDownload)
        {
            return Activity.Sequence(
                Activity.Run<DetailsAvailable>(a => a.ConvertToCpaXml(dataDownload)),
                Activity.Run<DocumentEvents>(d => d.UpdateFromPto(dataDownload)),
                Activity.Run<NewCaseDetailsNotification>(a => a.NotifyAlways(dataDownload)),
                Activity.Run<RuntimeEvents>(a => a.CaseProcessed(dataDownload)))
                .AnyFailed(Activity.Run<IDownloadFailedNotification>(d => d.Notify(dataDownload)));
        }

        static Activity AfterDownloadWithoutDocs(DataDownload dataDownload)
        {
            return Activity.Sequence(
                Activity.Run<DetailsAvailable>(a => a.ConvertToCpaXml(dataDownload)),
                Activity.Run<NewCaseDetailsNotification>(a => a.NotifyIfChanged(dataDownload)),
                Activity.Run<RuntimeEvents>(a => a.CaseProcessed(dataDownload)))
                .AnyFailed(Activity.Run<IDownloadFailedNotification>(d => d.Notify(dataDownload)));
        }
    }
}