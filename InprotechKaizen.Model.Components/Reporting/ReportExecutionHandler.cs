using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Integration.Jobs;

namespace InprotechKaizen.Model.Components.Reporting
{
    public class ReportExecutionHandler : IHandleAsync<ReportGenerationRequiredMessage>
    {
        readonly IJobArgsStorage _jobArgsStorage;
        readonly ILogger<ReportExecutionHandler> _logger;
        readonly IIntegrationServerClient _jobsServer;

        public ReportExecutionHandler(
            ILogger<ReportExecutionHandler> logger,
            IIntegrationServerClient jobsServer, IJobArgsStorage jobArgsStorage)
        {
            _logger = logger;
            _jobsServer = jobsServer;
            _jobArgsStorage = jobArgsStorage;
        }

        public async Task HandleAsync(ReportGenerationRequiredMessage message)
        {
            var storageId = await _jobArgsStorage.CreateAsync(message);

            await _jobsServer.Post("api/jobs/StandardReportExecutionJob/start", new {StorageId = storageId});

            _logger.Trace($"Dispatched report generation job, ContentId={message.ReportRequestModel.ContentId}");
        }
    }
}