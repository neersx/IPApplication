using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Jobs;
using InprotechKaizen.Model.Components.Names.Consolidation;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Names.Consolidations
{
    public class NameConsolidationJob : IPerformBackgroundJob
    {
        readonly IPersistJobState _persistJobState;

        public NameConsolidationJob(IPersistJobState persistJobState)
        {
            _persistJobState = persistJobState;
        }

        public string Type => nameof(NameConsolidationJob);

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            var args = jobArguments.ToObject<NameConsolidationArgs>();

            return Activity.Run<NameConsolidationJob>(_ => _.ConsolidateNames(jobExecutionId, args));
        }

        public Task<Activity> ConsolidateNames(long jobExecutionId, NameConsolidationArgs args)
        {
            var nameIds = args.NameIds.ToArray();

            var numberOfNamesToConsolidate = nameIds.Length;

            var initialiseJobState = Activity.Run<NameConsolidationJob>(_ => _.InitialiseJobState(jobExecutionId, numberOfNamesToConsolidate));

            var consolidationWorkflow = from id in nameIds
                                        let activities = BuildConsolidateEachNameWorkflow(jobExecutionId, args, id)
                                        select Activity.Sequence(activities)
                                                       .ExceptionFilter<IFailedConsolidatingName>((ex, f) => f.NameNotConsolidated(ex, jobExecutionId, id))
                                                       .ThenContinue();

            var completeJob = Activity.Run<NameConsolidationJob>(_ => _.CompleteJob(jobExecutionId));

            var entireWorkflow = initialiseJobState.Then(Activity.Sequence(consolidationWorkflow)).Then(completeJob);

            return Task.FromResult(entireWorkflow);
        }

        public async Task InitialiseJobState(long jobExecutionId, int namesToConsolidate)
        {
            await _persistJobState.Save(jobExecutionId, new NameConsolidationStatus{ NumberOfNamesToConsolidate = namesToConsolidate });
        }

        public async Task UpdateJobState(long jobExecutionId, int nameConsolidated)
        {
            var status = await _persistJobState.Load<NameConsolidationStatus>(jobExecutionId);
            status.NamesConsolidated.Add(nameConsolidated);
            await _persistJobState.Save(jobExecutionId, status);
        }

        public async Task CompleteJob(long jobExecutionId)
        {
            var status = await _persistJobState.Load<NameConsolidationStatus>(jobExecutionId);
            status.IsCompleted = true;
            await _persistJobState.Save(jobExecutionId, status);
        }

        static IEnumerable<Activity> BuildConsolidateEachNameWorkflow(long jobExecutionId, NameConsolidationArgs args, int thisNameId)
        {
            yield return Activity.Run<ISingleNameConsolidation>(_ => _.Consolidate(args.ExecuteAs, thisNameId, args.TargetId, args.KeepAddressHistory, args.KeepTelecomHistory, args.KeepConsolidatedName));

            yield return Activity.Run<NameConsolidationJob>(_ => _.UpdateJobState(jobExecutionId, thisNameId));
        }
    }
}