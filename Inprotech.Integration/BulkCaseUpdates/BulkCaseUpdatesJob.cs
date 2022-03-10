using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public class BulkCaseUpdatesJob : IPerformBackgroundJob
    {
        readonly IPersistJobState _persistJobState;

        public BulkCaseUpdatesJob(IPersistJobState persistJobState)
        {
            _persistJobState = persistJobState;
        }

        public string Type => nameof(BulkCaseUpdatesJob);

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            var args = jobArguments.ToObject<BulkCaseUpdatesArgs>();
            return Activity.Run<BulkCaseUpdatesJob>(_ => _.BulkUpdate(jobExecutionId, args));
        }

        public Task<Activity> BulkUpdate(long jobExecutionId, BulkCaseUpdatesArgs args)
        {
            var numberOfCases = args.CaseIds.Length;
            var initialiseJobState = Activity.Run<BulkCaseUpdatesJob>(_ => _.InitialiseJobState(jobExecutionId, numberOfCases));
            var bulkUpdate = Activity.Run<IBulkFieldUpdates>(_ => _.BulkUpdateCases(args));
            var completeJob = Activity.Run<BulkCaseUpdatesJob>(_ => _.CompleteJob(jobExecutionId));
            var configureNextJob = Activity.Run<IConfigureBulkCaseUpdatesJob>(_ => _.StartNextJob());

            var entireWorkflow = initialiseJobState.Then(bulkUpdate).Then(completeJob).Then(configureNextJob);
            return Task.FromResult(entireWorkflow);
        }

        public async Task InitialiseJobState(long jobExecutionId, int numberOfCasesToUpdate)
        {
            await _persistJobState.Save(jobExecutionId, new BulkCaseUpdatesStatus { NumberOfCasesToUpdate = numberOfCasesToUpdate});
        }

        public async Task CompleteJob(long jobExecutionId)
        {
            var status = await _persistJobState.Load<BulkCaseUpdatesStatus>(jobExecutionId);
            status.IsCompleted = true;
            await _persistJobState.Save(jobExecutionId, status);
        }
    }
}
