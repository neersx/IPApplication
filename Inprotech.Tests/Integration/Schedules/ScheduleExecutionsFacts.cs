using System.Linq;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class ScheduleExecutionsFacts : FactBase
    {
        public ScheduleExecutionsFacts()
        {
            var s = new Schedule {Id = 1};
            new ScheduleExecution
            {
                Status = ScheduleExecutionStatus.Failed,
                ScheduleId = 1,
                Schedule = s,
                CorrelationId = "12345",
                DocumentsIncluded = 1
            }.In(Db);

            new ScheduleExecution
            {
                Status = ScheduleExecutionStatus.Failed,
                ScheduleId = 2,
                Schedule = new Schedule {Id = 2, Parent = s},
                CorrelationId = "67890",
                DocumentsProcessed = 2
            }.In(Db);
        }

        [Fact]
        public void CorrelationIdIsReturned()
        {
            var scheduleExecutions = new ScheduleExecutions(Db);
            var r = scheduleExecutions.Get(1, null);
            Assert.Equal("12345", r.First().CorrelationId);
            Assert.Equal("67890", r.Last().CorrelationId);
        }

        [Fact]
        public void ReturnEmptyIfNoScheduleExecutionsFound()
        {
            var scheduleExecutions = new ScheduleExecutions(Db);
            var r = scheduleExecutions.Get(-1, null);
            Assert.Equal(0, r.Count());
        }

        [Fact]
        public void ShouldGetScheduleExecutionsForSchedule()
        {
            var scheduleExecutions = new ScheduleExecutions(Db);
            var r = scheduleExecutions.Get(1, ScheduleExecutionStatus.Failed);
            Assert.Equal(2, r.Count());
        }
        
        [Fact]
        public void ShouldGetScheduleExecutionsDocumentNumbers()
        {
            var scheduleExecutions = new ScheduleExecutions(Db);
            var r = scheduleExecutions.Get(1, ScheduleExecutionStatus.Failed);
            Assert.Equal(2, r.Count());
            Assert.Equal(1, r.First().DocumentsIncluded);
            Assert.Equal(2, r.Last().DocumentsProcessed);
        }
    }
}