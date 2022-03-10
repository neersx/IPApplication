using System.Linq;
using Inprotech.Setup.Actions;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class InstanceConfigurationReaderFacts
    {
        public class OwnIntegrationServer
        {
            [Fact]
            public void ShouldReadInprotechServerAppSettings()
            {
                var reader = new InstanceConfigurationReader();
                var settings = reader.Read("Assets/instance-1").Single(a => a.Name == "Inprotech Server").AppSettings;

                Assert.Equal("inprotech.server.appsettings", settings["name"]);
            }

            [Fact]
            public void ShouldReadInprotechServerConfiguration()
            {
                var reader = new InstanceConfigurationReader();
                var settings = reader.Read("Assets/instance-1").Single(a => a.Name == "Inprotech Server").Configuration;

                Assert.Equal("inprotech_connectionstring", settings["ConnectionString"]);
            }

            [Fact]
            public void ShouldReadIntegrationAppSettings()
            {
                var reader = new InstanceConfigurationReader();
                var settings = reader.Read("Assets/instance-1").Single(a => a.Name == "Inprotech Integration Server").AppSettings;

                Assert.Equal("inprotech.integration.appsettings", settings["name"]);
            }

            [Fact]
            public void ShouldReadIntegrationConfiguration()
            {
                var reader = new InstanceConfigurationReader();
                var settings = reader.Read("Assets/instance-1").Single(a => a.Name == "Inprotech Integration Server").Configuration;

                Assert.Equal("integration_connectionstring", settings["ConnectionString"]);
                Assert.Equal("Not Available", settings["Status"]);
                Assert.Equal("Not Available", settings["ServiceAccount"]);
            }
        }

        public class RemoteIntegrationServer
        {
            [Fact]
            public void ShouldReadIntegrationConfiguration()
            {
                var reader = new InstanceConfigurationReader();
                var settings = reader.Read("Assets/instance-2").Single(a => a.Name == "Inprotech Integration Server").Configuration;

                Assert.Equal("Not Installed", settings["Status"]);
                Assert.Equal("http://some.other.location.com/inprotech-integration-server", settings["Remote Instance"]);
                Assert.Equal(string.Empty, settings["Hide AppSettings"]);
            }
        }
    }
}