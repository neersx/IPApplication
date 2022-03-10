using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public class SendSelectedDocumentsToDms : IPerformBackgroundJob
    {
        readonly IBuildDmsIntegrationWorkflows _buildDmsIntegrationWorkflows;

        public SendSelectedDocumentsToDms(IBuildDmsIntegrationWorkflows buildDmsIntegrationWorkflows)
        {
            _buildDmsIntegrationWorkflows = buildDmsIntegrationWorkflows;
        }

        public Task<Activity> BuildJobWorkflow(long jobExecutionId)
        {
            return Task.FromResult(_buildDmsIntegrationWorkflows.BuildWorkflowToSendAnyDocumentsAtSendToDms(jobExecutionId));
        }

        public string Type => "SendSelectedDocumentsToDms";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<SendSelectedDocumentsToDms>(s => s.BuildJobWorkflow(jobExecutionId));
        }
    }

    public class SendPrivatePairDocumentsToDms : IPerformBackgroundJob
    {
        readonly IBuildDmsIntegrationWorkflows _buildDmsIntegrationWorkflows;

        public SendPrivatePairDocumentsToDms(IBuildDmsIntegrationWorkflows buildDmsIntegrationWorkflows)
        {
            _buildDmsIntegrationWorkflows = buildDmsIntegrationWorkflows;
        }

        public Task<Activity> BuildJobWorkflow(long jobExecutionId)
        {
            return Task.FromResult(_buildDmsIntegrationWorkflows.BuildWorkflowToSendAllDownloadedDocumentsToDms(DataSourceType.UsptoPrivatePair, jobExecutionId));
        }

        public string Type => "SendPrivatePairDocumentsToDms";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<SendPrivatePairDocumentsToDms>(s => s.BuildJobWorkflow(jobExecutionId));
        }
    }

    public class SendTsdrDocumentsToDms : IPerformBackgroundJob
    {
        readonly IBuildDmsIntegrationWorkflows _buildDmsIntegrationWorkflows;

        public SendTsdrDocumentsToDms(IBuildDmsIntegrationWorkflows buildDmsIntegrationWorkflows)
        {
            _buildDmsIntegrationWorkflows = buildDmsIntegrationWorkflows;
        }

        public Task<Activity> BuildJobWorkflow(long jobExecutionid)
        {
            return Task.FromResult(_buildDmsIntegrationWorkflows.BuildWorkflowToSendAllDownloadedDocumentsToDms(DataSourceType.UsptoTsdr, jobExecutionid));
        }

        public string Type => "SendTsdrDocumentsToDms";

        public SingleActivity GetJob(long jobExecutionid, JObject jobArguments)
        {
            return Activity.Run<SendTsdrDocumentsToDms>(s => s.BuildJobWorkflow(jobExecutionid));
        }
    }
}
