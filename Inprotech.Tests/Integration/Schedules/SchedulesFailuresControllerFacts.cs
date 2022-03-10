using Inprotech.Integration.Schedules;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class SchedulesFailuresControllerFacts : FactBase
    {
        public SchedulesFailuresControllerFacts()
        {
            _scheduleFailuresController = new ScheduleFailuresController(Db);
        }

        readonly ScheduleFailuresController _scheduleFailuresController;

        [Fact]
        public void ShouldReturnErrorLog()
        {
            new ScheduleFailure
                {
                    ScheduleExecutionId = 1,
                    Log = @"[{'message': 'error'}]"
                }
                .In(Db);

            var r = _scheduleFailuresController.Get(1);

            Assert.Equal("error", (string) r.Log[0].message);
        }
    }
}