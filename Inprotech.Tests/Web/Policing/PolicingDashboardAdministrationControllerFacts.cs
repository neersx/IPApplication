using Inprotech.Infrastructure.Security;
using Inprotech.Web.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingDashboardAdministrationControllerFacts
    {
        public class PolicingDashboardAdministrationControllerFixture : IFixture<PolicingDashboardAdministrationController>
        {
            public PolicingDashboardAdministrationControllerFixture()
            {
                PolicingBackgroundServer = Substitute.For<IPolicingBackgroundServer>();

                Subject = new PolicingDashboardAdministrationController(PolicingBackgroundServer);
            }

            public IPolicingBackgroundServer PolicingBackgroundServer { get; set; }
            public PolicingDashboardAdministrationController Subject { get; set; }
        }

        [Fact]
        public void RequiresPolicingAdministrationTask()
        {
            var r = TaskSecurity.Secures<PolicingDashboardAdministrationController>(ApplicationTask.PolicingAdministration);

            Assert.True(r);
        }

        [Fact]
        public void TurnOffThePolicingContinuous()
        {
            var f = new PolicingDashboardAdministrationControllerFixture();
            f.PolicingBackgroundServer.TurnOff();
            f.PolicingBackgroundServer.Received(1).TurnOff();
        }

        [Fact]
        public void TurnOnThePolicingContinuous()
        {
            var f = new PolicingDashboardAdministrationControllerFixture();
            f.PolicingBackgroundServer.TurnOn();
            f.PolicingBackgroundServer.Received(1).TurnOn();
        }
    }
}