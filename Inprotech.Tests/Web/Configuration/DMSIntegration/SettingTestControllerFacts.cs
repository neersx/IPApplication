using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Web.Configuration.DMSIntegration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.DMSIntegration
{
    public class SettingTestControllerFacts : FactBase
    {
        [Fact]
        public async Task ShouldCallSettingTesterTestConnections()
        {
            var fixture = new SettingTestControllerFixture();
            var connections = new ConnectionTestRequestModel
            {
                Settings = new List<IManageSettings.SiteDatabaseSettings>()
            };

            fixture.Subject.TestConnections(connections);

            fixture.SettingTester.Received(1).TestConnections(connections);
        }

        class SettingTestControllerFixture : IFixture<SettingTestController>
        {
            public SettingTestControllerFixture()
            {
                SettingTester = Substitute.For<ISettingTester>();
                Subject = new SettingTestController(SettingTester);
            }

            public ISettingTester SettingTester { get; }
            public SettingTestController Subject { get; }
        }
    }
}
