using Dependable;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using System;
using System.Linq;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public class LegacyFileCleanUp : IPerformBackgroundJob
    {
        readonly IRepository _repository;
        readonly ILegacyDirectories _legacyDirectories;

        public LegacyFileCleanUp(IRepository repository, ILegacyDirectories legacyDirectories)
        {
            _repository = repository;
            _legacyDirectories = legacyDirectories;
        }

        public string Type => "LegacyFileCleanUp";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<LegacyFileCleanUp>(fc => fc.CleanUp());
        }

        public Task<Activity> CleanUp()
        {
            var firstRun = DateTime.MaxValue;

            if (_repository.Set<ScheduleExecution>().Any())
            {
                firstRun = _repository.Set<ScheduleExecution>().Min(_ => _.Started);
            }

            var dirs = _legacyDirectories.Enumerate(firstRun);

            var guid = Guid.Empty;

            var activities = dirs.Select(dir => Activity.Sequence(
                Activity.Run<ICleanScheduleExecutionSessions>(c => c.Clean(guid, dir)),
                Activity.Run<ICleanUpFolders>(c => c.Clean(guid, dir)))
                    .ThenContinue());

            return Task.FromResult((Activity)Activity.Sequence(activities));
        }
    }
}
