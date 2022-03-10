using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public class ScheduleExecutionArtefactsCleanUp : IPerformBackgroundJob
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _now;

        public ScheduleExecutionArtefactsCleanUp(IRepository repository, Func<DateTime> now)
        {
            _repository = repository;
            _now = now;
        }

        public async Task Clean()
        {
            var executions = _repository.Set<ScheduleExecution>();
            var failures = _repository.Set<ScheduleFailure>();
            var recoverables = _repository.Set<ScheduleRecoverable>();
            var unrecoverables = _repository.Set<UnrecoverableArtefact>();
            var artifacts = _repository.Set<ScheduleExecutionArtifact>();
            var twoWeeksAgo = _now().Date.Subtract(TimeSpan.FromDays(14));
            var lookbackLimit = _now().Date.Subtract(TimeSpan.FromDays(100));

            var allSuccessfulExecutionsOverTwoWeeksOld =
                (from e in executions
                 join sf in failures on e.Id equals sf.ScheduleExecutionId into sfj
                 from sf in sfj.DefaultIfEmpty()
                 join r in recoverables on e.Id equals r.ScheduleExecutionId into rj
                 from r in rj.DefaultIfEmpty()
                 join ur in unrecoverables on e.Id equals ur.ScheduleExecutionId into urj
                 from ur in urj.DefaultIfEmpty()
                 where sf == null
                       && r == null
                       && ur == null
                       && e.Status == ScheduleExecutionStatus.Complete
                       && e.Finished != null
                       && e.Finished <= twoWeeksAgo && e.Finished > lookbackLimit
                 select e.Id)
                    .ToArray();

            if (!allSuccessfulExecutionsOverTwoWeeksOld.Any())
                return;
            
            await _repository
                .UpdateAsync(
                    from a in artifacts
                    where allSuccessfulExecutionsOverTwoWeeksOld.Contains(a.ScheduleExecutionId) && a.Blob != null
                    select a,
                    _ => new ScheduleExecutionArtifact { Blob = null }
                );
        }

        public string Type => "ScheduleExecutionArtefactsCleanUp";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<ScheduleExecutionArtefactsCleanUp>(_ => _.Clean());
        }
    }
}