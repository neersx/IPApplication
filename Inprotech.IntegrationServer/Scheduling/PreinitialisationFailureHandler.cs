using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

#pragma warning disable CS1998 // Async method lacks 'await' operators and will run synchronously

namespace Inprotech.IntegrationServer.Scheduling
{
    public class PreinitialisationFailureHandler
    {
        readonly IScheduleRuntimeEvents _runtimeEvents;
        readonly ScheduleExecutionResolver _scheduleExecutionResolver;

        public PreinitialisationFailureHandler(IScheduleRuntimeEvents runtimeEvents, ScheduleExecutionResolver scheduleExecutionResolver)
        {
            _runtimeEvents = runtimeEvents;
            _scheduleExecutionResolver = scheduleExecutionResolver;
        }

        public async Task Terminate(int scheduleId, Guid cancellationToken)
        {
            var scheduleExecution = _scheduleExecutionResolver.Resolve(scheduleId, cancellationToken);
            if (scheduleExecution == null) return;
            _runtimeEvents.End(scheduleExecution.SessionGuid);
        }
    }

    public class ScheduleExecutionResolver
    {
        readonly IRepository _repository;

        public ScheduleExecutionResolver(IRepository repository)
        {
            _repository = repository;
        }

        public ScheduleExecution Resolve(int scheduleId, Guid cancellationToken)
        {
            var cancellationTokenString = cancellationToken.ToString();

            return _repository.Set<ScheduleExecution>()
                              .Where(_ => _.ScheduleId == scheduleId && _.Finished == null && _.CancellationData.Contains(cancellationTokenString))
                              .OrderByDescending(_ => _.Started)
                              .FirstOrDefault();
        }
    }
}