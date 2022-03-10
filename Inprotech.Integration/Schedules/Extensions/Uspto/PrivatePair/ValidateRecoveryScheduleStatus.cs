using System;
using System.Data.Entity;
using System.Linq;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair
{
    class ValidateUsptoRecoveryScheduleStatus : IValidateRecoveryScheduleStatus
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _now;

        public ValidateUsptoRecoveryScheduleStatus(IRepository repository, Func<DateTime> now)
        {
            _repository = repository;
            _now = now;
        }

        public RecoveryScheduleStatus Status(Schedule retrySchedule, ScheduleExecution retryRun)
        {
            if (retrySchedule == null || retrySchedule.DataSourceType != DataSourceType.UsptoPrivatePair)
                throw new Exception("Invalid Data Source for Recovery Schedule Status");

            if (retryRun == null)
                return RecoveryScheduleStatus.Pending;

            if (retryRun.Started.Date == _now().Date)
                return RecoveryScheduleStatus.Running;

            var latestCompleted = _repository.Set<Schedule>()
                                             .Include(_ => _.Executions)
                                             .Where(_ => _.ParentId == retrySchedule.ParentId && _.Type == ScheduleType.Scheduled
                                                                                              && _.CreatedOn > retrySchedule.CreatedOn
                                                                                              && _.Executions.Any(se => se.Finished != null))
                                             .OrderByDescending(_ => _.CreatedOn)
                                             .FirstOrDefault();

            if (latestCompleted == null)
                return RecoveryScheduleStatus.Running;

            return RecoveryScheduleStatus.Idle;
        }
    }
}