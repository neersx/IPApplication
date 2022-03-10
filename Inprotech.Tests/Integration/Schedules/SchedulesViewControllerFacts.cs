using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class SchedulesViewControllerFacts
    {
        public SchedulesViewControllerFacts()
        {
            _scheduleDetails = Substitute.For<IScheduleDetails>();
            _subject = new SchedulesViewController(_scheduleDetails);
        }

        readonly SchedulesViewController _subject;
        readonly IScheduleDetails _scheduleDetails;

        [Fact]
        public void CallsScheduleDetailsWithParams()
        {
            _subject.Get();

            _scheduleDetails.Received(1).Get();
        }
    }
}