using System;
using System.ComponentModel;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules.Extensions.Uspto.PrivatePair
{
    public class ValidateUsptoRecoveryScheduleStatusFacts : FactBase
    {
        IValidateRecoveryScheduleStatus Subject() => new ValidateUsptoRecoveryScheduleStatus(Db, Fixture.Today);

        [Fact]
        public void ThrowsExceptionIfInvalidData()
        {
            var retrySchedule = new Schedule { DataSourceType = DataSourceType.Epo };
            var f = Subject();

            Assert.Throws<Exception>(() => f.Status(null, null));

            Assert.Throws<Exception>(() => f.Status(retrySchedule, null));
        }

        [Fact]
        public void ReturnsPendingStatusIfScheduleNotStartedYet()
        {
            var retrySchedule = new Schedule { DataSourceType = DataSourceType.UsptoPrivatePair, Type = ScheduleType.Retry };
            var f = Subject();

            Assert.Equal(RecoveryScheduleStatus.Pending, f.Status(retrySchedule, null));
        }

        [Fact]
        public void ReturnsRunningForSameDayRetrySchedule()
        {
            var retrySchedule = new Schedule { DataSourceType = DataSourceType.UsptoPrivatePair, Type = ScheduleType.Retry };
            var se = new ScheduleExecution() { Started = Fixture.Today() };
            var f = Subject();

            Assert.Equal(RecoveryScheduleStatus.Running, f.Status(retrySchedule, se));
        }

        [Fact]
        public void ReturnsRunningIfNormalScheduleNotCompletedAfterRetry()
        {
            var parent = new Schedule() { DataSourceType = DataSourceType.UsptoPrivatePair, Type = ScheduleType.Continuous }.In(Db);
            var retrySchedule = new Schedule { DataSourceType = parent.DataSourceType, ParentId = parent.Id, Type = ScheduleType.Retry, CreatedOn = Fixture.PastDate() };
            var se = new ScheduleExecution() { Started = Fixture.PastDate() };

            Assert.Equal(RecoveryScheduleStatus.Running, Subject().Status(retrySchedule, se));

            var completedScheduleInDb = new Schedule()
            {
                DataSourceType = parent.DataSourceType,
                ParentId = parent.Id,
                Type = ScheduleType.Scheduled,
                CreatedOn = Fixture.PastDate(),
                Executions = new BindingList<ScheduleExecution>
                {
                    new ScheduleExecution().In(Db)
                }
            }.In(Db);

            Assert.Equal(RecoveryScheduleStatus.Running, Subject().Status(retrySchedule, se));
        }

        [Fact]
        public void ReturnsIdleIfNormalScheduleHasCompletedAfterRetry()
        {
            var parent = new Schedule() { DataSourceType = DataSourceType.UsptoPrivatePair, Type = ScheduleType.Continuous }.In(Db);
            var retrySchedule = new Schedule { DataSourceType = parent.DataSourceType, ParentId = parent.Id, Type = ScheduleType.Retry, CreatedOn = Fixture.PastDate() };
            var se = new ScheduleExecution() { Started = Fixture.PastDate() };

            var completedScheduleInDb = new Schedule()
            {
                DataSourceType = parent.DataSourceType,
                ParentId = parent.Id,
                Type = ScheduleType.Scheduled,
                CreatedOn = Fixture.Today(),
                Executions = new BindingList<ScheduleExecution>
                {
                    new ScheduleExecution { Finished = Fixture.Today() }.In(Db)
                }
            }.In(Db);
            var f = Subject();

            Assert.Equal(RecoveryScheduleStatus.Idle, f.Status(retrySchedule, se));
        }
    }
}