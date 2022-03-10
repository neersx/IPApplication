using System;
using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class UpdateScheduleStateFacts : FactBase
    {
        [Theory]
        [InlineData("Mon")]
        [InlineData("")]
        public void SetsExpiredSchedulesToExpired(string runOnDays)
        {
            var f = new UpdateScheduleStateFixture();

            var schedule = new Schedule
            {
                Id = 1,
                State = ScheduleState.Active,
                NextRun = null,
                RunOnDays = runOnDays,
                ExpiresAfter = f.Today().AddDays(-1)
            };

            f.Subject.For(schedule);

            Assert.Equal(ScheduleState.Expired, schedule.State);
        }

        public class UpdateScheduleStateFixture : IFixture<UpdateScheduleState>
        {
            public UpdateScheduleStateFixture()
            {
                Today = Substitute.For<Func<DateTime>>();
                Today().Returns(Fixture.Today());
                Subject = new UpdateScheduleState(Today);
            }

            public Func<DateTime> Today { get; }
            public UpdateScheduleState Subject { get; set; }
        }

        [Fact]
        public void DoesNotExpireOnExpiresAfterDate()
        {
            var f = new UpdateScheduleStateFixture();

            var schedule = new Schedule
            {
                Id = 1,
                State = ScheduleState.Active,
                NextRun = Fixture.Today(),
                RunOnDays = "Mon",
                ExpiresAfter = f.Today()
            };

            f.Subject.For(schedule);

            Assert.Equal(ScheduleState.Active, schedule.State);
        }

        [Fact]
        public void SetsPurgatorySchedulesToExpiredOnceExpired()
        {
            var f = new UpdateScheduleStateFixture();

            var schedule = new Schedule
            {
                Id = 1,
                State = ScheduleState.Purgatory,
                NextRun = null,
                RunOnDays = "Mon",
                ExpiresAfter = f.Today().AddDays(-1)
            };

            f.Subject.For(schedule);

            Assert.Equal(ScheduleState.Expired, schedule.State);
        }

        [Fact]
        public void SetsRunNowPurgatorySchedulesToExpired()
        {
            var f = new UpdateScheduleStateFixture();

            var schedule = new Schedule
            {
                Id = 1,
                State = ScheduleState.Purgatory,
                NextRun = null,
                Parent = new Schedule()
            };

            f.Subject.For(schedule);

            Assert.Equal(ScheduleState.Expired, schedule.State);
        }

        [Fact]
        public void SetsRunNowStateToPurgatory()
        {
            var f = new UpdateScheduleStateFixture();

            var schedule = new Schedule
            {
                Id = 1,
                State = ScheduleState.RunNow
            };

            f.Subject.For(schedule);

            Assert.Equal(ScheduleState.Purgatory, schedule.State);
        }

        [Fact]
        public void SetsRunOncePurgatorySchedulesToExpired()
        {
            var f = new UpdateScheduleStateFixture();

            var schedule = new Schedule
            {
                Id = 1,
                State = ScheduleState.Purgatory,
                NextRun = null,
                ExpiresAfter = f.Today().AddDays(5)
            };

            f.Subject.For(schedule);

            Assert.Equal(ScheduleState.Expired, schedule.State);
        }

        [Fact]
        public void SetsSchedulesNoLongerRunningButWithNoExpiryToPurgatory()
        {
            var f = new UpdateScheduleStateFixture();

            var schedule = new Schedule
            {
                Id = 1,
                State = ScheduleState.Active,
                NextRun = null,
                RunOnDays = "Mon",
                ExpiresAfter = f.Today().AddDays(1)
            };

            f.Subject.For(schedule);

            Assert.Equal(ScheduleState.Purgatory, schedule.State);
        }

        [Fact]
        public void SetsSchedulesStillRunningToActive()
        {
            var f = new UpdateScheduleStateFixture();

            var schedule = new Schedule
            {
                Id = 1,
                NextRun = f.Today(),
                ExpiresAfter = f.Today().AddDays(10)
            };

            f.Subject.For(schedule);

            Assert.Equal(ScheduleState.Active, schedule.State);
        }
    }
}