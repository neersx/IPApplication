using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class RecoveryScheduleControllerFacts : FactBase
    {
        [Fact]
        public void CallsRecoverableScheduleRecovery()
        {
            var f = new RecoveryScheduleControllerFixture();

            f.Subject.Recover(10);

            f.RecoverableSchedule.Received(1).Recover(10);
        }
    }

    public class RecoveryScheduleControllerFixture : IFixture<RecoveryScheduleController>
    {
        public IRecoverableSchedule RecoverableSchedule = Substitute.For<IRecoverableSchedule>();

        public RecoveryScheduleControllerFixture()
        {
            Subject = new RecoveryScheduleController(RecoverableSchedule);
        }

        public RecoveryScheduleController Subject { get; }
    }
}