using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Settings;
using Document = Inprotech.Integration.Documents.Document;

#pragma warning disable CS1998 // Async method lacks 'await' operators and will run synchronously

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IBuildDmsIntegrationWorkflows
    {
        Activity Build(Case @case, IEnumerable<Document> documents);
        Task<Activity> BuildTsdr(DataDownload dataDownload);
        Activity BuildPrivatePair(ApplicationDownload applicationDownload);
        Activity BuildWorkflowToSendAllDownloadedDocumentsToDms(DataSourceType source, long jobExecutionId);
        Activity BuildWorkflowToSendAnyDocumentsAtSendToDms(long jobExecutionId);
    }

    public class DmsIntegrationWorkflow : IBuildDmsIntegrationWorkflows
    {
        readonly ILoadCaseAndDocuments _loader;
        readonly IDmsIntegrationSettings _settings;

        public DmsIntegrationWorkflow(ILoadCaseAndDocuments loader, IDmsIntegrationSettings settings)
        {
            _loader = loader;
            _settings = settings;
        }

        Activity SetToDownloaded(IEnumerable<Document> documents)
        {
            var docIds = documents.Select(d => d.Id).ToArray();
            return Activity.Run<IUpdateDocumentStatus>(
                updater => updater.UpdateAllTo(docIds, DocumentDownloadStatus.Downloaded));
        }
        
        public Activity Build(Case @case, IEnumerable<Document> documents)
        {
            if (!@case.CorrelationId.HasValue)
            {
                return SetToDownloaded(documents);
            }

            var caseId = @case.Id;
            var docs = documents.ToArray();

            return !docs.Any()
                ? DefaultActivity.NoOperation()
                : Activity.Sequence(
                    docs.Select(
                        doc =>
                            Activity
                                .Run<IMoveDocumentToDmsFolder>(sender => sender.MoveToDms(caseId, doc.Id))
                                .ExceptionFilter<IFailedSendingDocumentToDms>((ex, f) => f.Fail(ex, doc.Id))
                                .ThenContinue())
                    );
        }

        public async Task<Activity> BuildTsdr(DataDownload dataDownload)
        {
            if (!_settings.TsdrIntegrationEnabled) return DefaultActivity.NoOperation();
            var caseAndDocs = _loader.GetCaseAndDocuments(dataDownload);
            return Build(caseAndDocs.Case,
                caseAndDocs.Documents.Where(d => d.Status == DocumentDownloadStatus.ScheduledForSendingToDms));
        }

        public Activity BuildPrivatePair(ApplicationDownload applicationDownload)
        {
            if (!_settings.PrivatePairIntegrationEnabled) return DefaultActivity.NoOperation();
            var caseAndDocs = _loader.GetCaseAndDocuments(applicationDownload);
            return Build(caseAndDocs.Case,
                caseAndDocs.Documents.Where(d => d.Status == DocumentDownloadStatus.ScheduledForSendingToDms));
        }

        public Activity BuildWorkflowToSendAnyDocumentsAtSendToDms(long jobExecutionId)
        {
            var docIds = _loader.GetAnyDocumentsAtSendToDms().Select(d => d.Id).ToArray();
            return !docIds.Any()
                ? Activity.Run<IUpdateDmsIntegrationJobStates>(u => u.JobStarted(jobExecutionId, 0))
                : BuildWorkflowToSendAllSpecifiedDocumentsToDms(docIds, jobExecutionId);
        }

        public Activity BuildWorkflowToSendAllDownloadedDocumentsToDms(DataSourceType source, long jobExecutionId)
        {
            var docIds = _loader.GetDownloadedDocumentsToSendToDms(source).Select(d => d.Id).ToArray();
            return !docIds.Any()
                ? Activity.Run<IUpdateDmsIntegrationJobStates>(u => u.JobStarted(jobExecutionId, 0))
                : BuildWorkflowToSendAllSpecifiedDocumentsToDms(docIds, jobExecutionId);
        }

        Activity BuildWorkflowToSendAllSpecifiedDocumentsToDms(IEnumerable<int> docIds, long jobExecutionId)
        {
            var ids = docIds.ToArray();
            var total = ids.Length;

            return Activity.Sequence(
                Activity.Run<IUpdateDmsIntegrationJobStates>(u => u.JobStarted(jobExecutionId, total)),
                Activity.Sequence(
                    ids.Select(d =>
                        Activity.Sequence(
                            Activity.Run<ILoadCaseAndSendDocumentToDms>(sender => sender.SendToDms(d)),
                            Activity.Run<IUpdateDmsIntegrationJobStates>(u => u.DocumentSent(jobExecutionId))
                            )
                            .ExceptionFilter<IFailedSendingDocumentToDms>((ex, f) => f.Fail(ex, d))
                            .ThenContinue()
                        )
                    ).ThenContinue()
                );
        }
    }
}