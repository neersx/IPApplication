using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public class FileCleanUp : IPerformBackgroundJob
    {
        readonly IRepository _repository;
        readonly IResolveScheduleExecutionRootFolder _rootResolver;

        public FileCleanUp(IRepository repository, IResolveScheduleExecutionRootFolder rootResolver)
        {
            _repository = repository;
            _rootResolver = rootResolver;
        }

        public string Type => "FileCleanUp";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            var sessionGuidsToCheck = _repository.Set<ScheduleExecution>()
                                                 .Where(se => !se.IsTidiedUp && (se.Status == ScheduleExecutionStatus.Complete || se.Status == ScheduleExecutionStatus.Cancelled))
                                                 .Select(se => se.SessionGuid)
                                                 .ToList();

            return Activity.Run<FileCleanUp>(fc => fc.CleanUp(jobExecutionId, sessionGuidsToCheck));
        }

        public Task<Activity> CleanUp(long jobExecutionId, IList<Guid> sessionGuidsToCheck)
        {
            if (sessionGuidsToCheck == null) throw new ArgumentNullException(nameof(sessionGuidsToCheck));

            var activities = sessionGuidsToCheck.Select(sessionGuid =>
                                                        {
                                                            var sessionRootFolder = _rootResolver.Resolve(sessionGuid);
                                                            return Activity.Sequence(
                                                                                     Activity.Run<ICleanScheduleExecutionSessions>(c => c.Clean(sessionGuid, sessionRootFolder)),
                                                                                     Activity.Run<ICleanUpFolders>(c => c.Clean(sessionGuid, sessionRootFolder)),
                                                                                     Activity.Run<IUpdateScheduleExecutionStatus>(u => u.SetToTidiedUp(sessionGuid)))
                                                                           .ThenContinue();
                                                        });

            return Task.FromResult((Activity) Activity.Sequence(activities));
        }
    }
}