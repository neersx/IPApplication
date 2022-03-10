using System;
using System.Linq;
using Autofac.Features.Indexed;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Schedules
{
    public interface IValidateRecoveryScheduleStatus
    {
        RecoveryScheduleStatus Status(Schedule retrySchedule, ScheduleExecution retryRun);
    }
    public enum RecoveryScheduleStatus
    {
        Idle,
        Pending,
        Running
    }

    public interface IRecoveryScheduleStatusReader
    {
        RecoveryScheduleStatus Read(int parentScheduleId);
    }

    class RecoveryScheduleStatusReader : IRecoveryScheduleStatusReader
    {
        readonly IRepository _repository;
        readonly IIndex<DataSourceType, Func<IValidateRecoveryScheduleStatus>> _scheduleValidator;

        public RecoveryScheduleStatusReader(IRepository repository, IIndex<DataSourceType, Func<IValidateRecoveryScheduleStatus>> scheduleValidator)
        {
            _repository = repository;
            _scheduleValidator = scheduleValidator;
        }

        public RecoveryScheduleStatus Read(int parentScheduleId)
        {
            var schedule = _repository.Set<Schedule>()
                                      .Where(_ => _.ParentId == parentScheduleId && _.Type == ScheduleType.Retry)
                                      .OrderByDescending(_ => _.CreatedOn)
                                      .FirstOrDefault();

            if (schedule == null)
                return RecoveryScheduleStatus.Idle;

            var run = schedule.Executions.FirstOrDefault();

            if (run == null)
                return RecoveryScheduleStatus.Pending;

            if (run.Status == ScheduleExecutionStatus.Started)
                return RecoveryScheduleStatus.Running;

            if (_scheduleValidator.TryGetValue(schedule.DataSourceType, out var postValidator))
                return postValidator().Status(schedule, run);

            return RecoveryScheduleStatus.Idle;
        }
    }
}