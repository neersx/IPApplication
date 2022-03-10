using System;
using System.Threading.Tasks;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.Scheduling;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Scheduling
{
    public class PendingScheduleInterrupterFacts : FactBase
    {
        [Theory]
        [InlineData(0)]
        [InlineData(1)]
        public async Task ShouldPublishSchedulesDueToday(int offsetInHours)
        {
            var mondaySchedule = new Schedule {RunOnDays = "Mon", NextRun = Fixture.Monday}.In(Db);
            var tuesdaySchedule = new Schedule {RunOnDays = "Tue", NextRun = Fixture.Tuesday}.In(Db);

            var now = Fixture.Monday + TimeSpan.FromHours(offsetInHours);

            var fixture =
                new PendingScheduleInterrupterFixture(Db).WithNow(now).WithScheduleRunnerReady();

            await fixture.Subject.Interrupt();

            fixture.ScheduleRunner.Received(1).Run(mondaySchedule);
            fixture.ScheduleRunner.DidNotReceive().Run(tuesdaySchedule);
            fixture.PopulateNextRun.Received(1).For(mondaySchedule);

            Assert.Equal(mondaySchedule.LastRunStartOn, now);
        }

        [Fact]
        public async Task ShouldNotPublishScheduleOnTheSameDay()
        {
            var nextMonday = Fixture.Monday.AddDays(7);

            var theSchedule = new Schedule {RunOnDays = "Mon", LastRunStartOn = Fixture.Monday, NextRun = nextMonday}.In(Db);

            var fixture = new PendingScheduleInterrupterFixture(Db).WithNow(Fixture.Monday).WithScheduleRunnerReady();

            await fixture.Subject.Interrupt();

            fixture.ScheduleRunner.DidNotReceiveWithAnyArgs().Run(theSchedule);
            fixture.PopulateNextRun.DidNotReceiveWithAnyArgs().For(Arg.Any<Schedule>());

            Assert.Equal(theSchedule.LastRunStartOn, Fixture.Monday);
        }

        [Fact]
        public async Task ShouldNotDispatchIfScheduleRunnerIsNotReady()
        {
            new Schedule {RunOnDays = "Mon,Tue,Wed,Thu,Fri,Sat,Sun", NextRun = Fixture.PastDate()}.In(Db);
            
            var fixture = new PendingScheduleInterrupterFixture(Db).WithNow(Fixture.Today());

            await fixture.Subject.Interrupt();

            fixture.ScheduleRunner.DidNotReceive().Run(Arg.Any<Schedule>());
        }
    }

    public class PendingScheduleInterrupterFixture : IFixture<PendingScheduleInterrupter>
    {
        readonly InMemoryDbContext _db;

        public PendingScheduleInterrupterFixture(InMemoryDbContext db)
        {
            _db = db;
            Now = DateTime.Now;
            PopulateNextRun = Substitute.For<IPopulateNextRun>();
            ScheduleRunner = Substitute.For<IScheduleRunner>();
            UpdateScheduleState = Substitute.For<IUpdateScheduleState>();
        }

        public DateTime Now { get; private set; }

        public IPopulateNextRun PopulateNextRun { get; }

        public IUpdateScheduleState UpdateScheduleState { get; }

        public IScheduleRunner ScheduleRunner { get; set; }

        public PendingScheduleInterrupter Subject
        {
            get
            {
                return new PendingScheduleInterrupter(
                                                      _db,
                                                      () => Now,
                                                      ScheduleRunner,
                                                      PopulateNextRun,
                                                      UpdateScheduleState);
            }
        }

        public PendingScheduleInterrupterFixture WithNow(DateTime now)
        {
            Now = now;
            return this;
        }

        public PendingScheduleInterrupterFixture WithScheduleRunnerReady()
        {
            ScheduleRunner.IsReady.Returns(true);
            return this;
        }
    }
}