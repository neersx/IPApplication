using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Settings;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ViewCaseDataComparison)]
    [RequiresAccessTo(ApplicationTask.SaveImportedCaseData, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.ConfigureDmsIntegration)]
    [RoutePrefix("api/dms")]
    public class SendToDmsController : ApiController
    {
        readonly IDmsIntegrationSettings _settings;
        readonly IConfigureJob _configureJob;
        readonly IRepository _repository;
        readonly IDocumentLoader _documentLoader;

        public SendToDmsController(IDmsIntegrationSettings settings, IConfigureJob configureJob,
            IRepository repository, IDocumentLoader documentLoader)
        {
            _settings = settings;
            _configureJob = configureJob;
            _repository = repository;
            _documentLoader = documentLoader;
        }

        [HttpPost]
        [Route("send/{dataSource}")]
        public void SendDocumentsFromSource(DataSourceType dataSource)
        {
            if (!_settings.IsEnabledFor(dataSource))
                throw new ArgumentException("DMS Integration is not enabled");

            _configureJob.StartJob(DataSourceHelper.GetJobType(dataSource));
        }

        [HttpPost]
        [Route("job/{jobExecutionId}/status")]
        public async Task AcknowledgeStatus(long jobExecutionId)
        {
            await _configureJob.Acknowledge(jobExecutionId);
        }
        
        [HttpPost]
        [RequiresCaseAuthorization]
        [Route("send/{dataSource}/case/{caseId}")]
        public void SendDocumentsFromSourceForCase(DataSourceType dataSource, int? caseId)
        {
            if (caseId == null) throw new ArgumentNullException("caseId");
            if (!_settings.IsEnabledFor(dataSource))
                throw new ArgumentException("DMS Integration is not enabled");

            var importedRefs = _documentLoader.GetImportedRefs(caseId);

            var documents =
                _documentLoader.GetDocumentsFrom(dataSource, caseId)
                    .Where(
                        _ =>
                            (_.Status == DocumentDownloadStatus.Downloaded ||
                             _.Status == DocumentDownloadStatus.FailedToSendToDms) &&
                            !importedRefs.Contains(_.Reference));

            foreach (var doc in documents)
            {
                doc.Status = DocumentDownloadStatus.SendToDms;
            }
            _repository.SaveChanges();
        }
    }
}
