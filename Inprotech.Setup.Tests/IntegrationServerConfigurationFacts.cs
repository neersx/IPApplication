using System;
using Inprotech.Setup.Core;
using Inprotech.Setup.Pages;
using Xunit;

namespace Inprotech.Setup.Tests
{
    public class IntegrationServerConfigurationFacts
    {
        [Theory]
        [InlineData("http://host.com:32156/inprotech-integration-server-cpainpro/")]
        [InlineData("http://host.com:32156/inprotech-integration-server-cpainpro")]
        public void ShouldIdentifyEnteredUrl(string url)
        {
            var expectedUrl = url.Replace("*", Environment.MachineName).TrimEnd('/');

            var instanceServiceStatus = new InstanceServiceStatus
            {
                Endpoints = new[] {url}
            };

            var r = new IntegrationServerConfiguration(instanceServiceStatus);

            Assert.Equal(expectedUrl, r.EnteredUrl);
        }

        [Theory]
        [InlineData("http://host.com:32156/inprotech-integration-server-cpainpro/")]
        [InlineData("http://host.com:32156/inprotech-integration-server-cpainpro")]
        public void ShouldIdentifyLastPath(string url)
        {
            var instanceServiceStatus = new InstanceServiceStatus
            {
                Endpoints = new[] {url}
            };

            var r = new IntegrationServerConfiguration(instanceServiceStatus);

            Assert.Equal("/inprotech-integration-server-cpainpro", r.LastPath);
        }

        [Theory]
        [InlineData("http://*:32156/inprotech-integration-server-cpainpro/")]
        [InlineData("http://*:32156/inprotech-integration-server-cpainpro")]
        public void ShouldRemoveEndingSlashForOriginalBindingUrl(string url)
        {
            var instanceServiceStatus = new InstanceServiceStatus
            {
                MachineName = Environment.MachineName,
                Endpoints = new[] {url}
            };

            var r = new IntegrationServerConfiguration(instanceServiceStatus);

            Assert.Equal($"http://{Environment.MachineName}:32156/inprotech-integration-server-cpainpro", r.OriginalBindingUrl);
        }

        [Fact]
        public void ShouldCopyInstanceServiceStatusValues()
        {
            var instanceServiceStatus = new InstanceServiceStatus
            {
                Name = "a",
                MachineName = "b",
                Version = "c",
                Utc = DateTime.UtcNow,
                Status = ServiceStatus.Offline
            };

            var r = new IntegrationServerConfiguration(instanceServiceStatus);

            Assert.Equal(instanceServiceStatus.Name, r.Name);
            Assert.Equal(instanceServiceStatus.MachineName, r.MachineName);
            Assert.Equal(instanceServiceStatus.Version, r.Version);
            Assert.Equal(instanceServiceStatus.Utc, r.Utc);
            Assert.Equal(instanceServiceStatus.Status, r.Status);
            Assert.Empty(r.Endpoints);
            Assert.Null(r.EnteredUrl);
            Assert.Null(r.OriginalBindingUrl);
        }
    }
}