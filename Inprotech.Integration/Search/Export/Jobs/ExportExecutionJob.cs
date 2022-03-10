using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Search.Export.Jobs
{
    public class ExportExecutionJob : IPerformImmediateBackgroundJob
    {
        public string Type => nameof(ExportExecutionJob);

        public SingleActivity GetJob(JObject jobArguments)
        {
            var storageId = jobArguments["StorageId"].Value<int>();
            return Activity.Run<ExportExecutionJob>(_ => _.ExecuteExport(storageId));
        }

        public Task<Activity> ExecuteExport(int storageId)
        {
            var executeReport = Activity.Run<ExportExecutionEngine>(_ => _.Execute(storageId));
            var cleanupTempStorage = Activity.Run<ExportExecutionEngine>(_ => _.CleanUpTempStorage(storageId));

            return Task.FromResult(Activity.Sequence(executeReport, cleanupTempStorage)
                                   .ExceptionFilter<ExportExecutionEngine>((exception, c) => c.HandleException(exception, storageId))
                                   .ThenContinue());
        }
    }
}
