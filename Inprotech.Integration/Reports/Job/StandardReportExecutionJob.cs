using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Reports.Engine;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Reports.Job
{
    public class StandardReportExecutionJob : IPerformImmediateBackgroundJob
    {
        public string Type => nameof(StandardReportExecutionJob);

        public SingleActivity GetJob(JObject jobArguments)
        {
            var storageId = jobArguments["StorageId"].Value<long>();

            return Activity.Run<StandardReportExecutionJob>(_ => _.RenderReport(storageId));
        }

        public Task<Activity> RenderReport(long storageId)
        {
            var executeJobWorkflow = Activity.Run<ReportEngine>(_ => _.Execute(storageId))
                                             .ExceptionFilter<ReportEngine>((exception, c) => c.HandleException(exception, storageId));

            return Task.FromResult((Activity)executeJobWorkflow);
        }
    }
}