using System;
using System.Linq;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class ScheduleRuntimeEventsFacts
    {
        public class CancelMethod : FactBase
        {
            [Theory]
            [InlineData(ScheduleExecutionStatus.Complete)]
            [InlineData(ScheduleExecutionStatus.Failed)]
            public void DoesNotCancelFinishedScheduleExecution(ScheduleExecutionStatus currentStatus)
            {
                var sessionId = Guid.NewGuid();
                new ScheduleExecution(sessionId, new Schedule(), Fixture.Monday) {Status = currentStatus}.In(Db);

                var f = new ScheduleRuntimeEventsFixture(Db);
                f.Subject.Cancel(sessionId);

                var scheduleExecution = Db.Set<ScheduleExecution>().Single();
                Assert.NotEqual(ScheduleExecutionStatus.Cancelled, scheduleExecution.Status);
            }

            [Fact]
            public void CancelsRunningScheduleExecution()
            {
                var sessionId = Guid.NewGuid();
                new ScheduleExecution(sessionId, new Schedule(), Fixture.Monday) {Status = ScheduleExecutionStatus.Started}.In(Db);

                var f = new ScheduleRuntimeEventsFixture(Db);
                f.Subject.Cancel(sessionId);

                var scheduleExecution = Db.Set<ScheduleExecution>().Single();
                Assert.Equal(ScheduleExecutionStatus.Cancelled, scheduleExecution.Status);
            }
        }
    }

    public class ScheduleRuntimeEventsFixture : IFixture<IScheduleRuntimeEvents>
    {
        public ScheduleRuntimeEventsFixture(InMemoryDbContext db)
        {
            ScheduleExecutionManager = Substitute.For<IScheduleExecutionManager>();

            Subject = new ScheduleRuntimeEvents(db, ScheduleExecutionManager, Fixture.PastDate);
        }

        public IScheduleExecutionManager ScheduleExecutionManager { get; }
        public IScheduleRuntimeEvents Subject { get; }
    }
}