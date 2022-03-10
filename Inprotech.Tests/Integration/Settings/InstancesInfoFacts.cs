using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Integration.Settings;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Settings
{
    public class InstancesInfoFacts
    {
        [Fact]
        public void ReturnsIntegrationInstances()
        {
            var f = new InstancesInfoFixture();

            var result = f.Subject.IntegrationServerInstances();

            Assert.True(f.Instances.SequenceEqual(result, new InstanceServiceStatusComparer()));
        }

        [Fact]
        public void ReturnsServerInstance()
        {
            var f = new InstancesInfoFixture();

            var result = f.Subject.ServerInstances();

            Assert.True(f.Instances.SequenceEqual(result, new InstanceServiceStatusComparer()));
        }
    }

    public class InstancesInfoFixture : IFixture<IInstancesInfo>
    {
        public InstancesInfoFixture()
        {
            ServerConfig = Substitute.For<IGroupedConfig>();
            IntegrationConfig = Substitute.For<IGroupedConfig>();

            Subject = new InstancesInfo(GroupedConfig);
        }

        public InstanceServiceStatus[] Instances { get; private set; }
        public IGroupedConfig ServerConfig { get; }
        public IGroupedConfig IntegrationConfig { get; }
        public IInstancesInfo Subject { get; }

        IGroupedConfig GroupedConfig(string s)
        {
            Instances = new[]
            {
                new InstanceServiceStatus {MachineName = "La La Land", Name = "Alice", Status = ServiceStatus.Online, Utc = DateTime.UtcNow, Version = "1.0"},
                new InstanceServiceStatus {MachineName = "Moonlight", Name = "July", Status = ServiceStatus.Offline, Utc = DateTime.UtcNow, Version = "2.0"}
            };

            if (s == "Inprotech.Server")
            {
                ServerConfig.GetValues("Instances").Returns(new Dictionary<string, string> {{"Instances", JsonConvert.SerializeObject(Instances)}});
                return ServerConfig;
            }

            if (s == "Inprotech.IntegrationServer")
            {
                IntegrationConfig.GetValues("Instances").Returns(new Dictionary<string, string> {{"Instances", JsonConvert.SerializeObject(Instances)}});
                return IntegrationConfig;
            }

            return null;
        }
    }

    public class InstanceServiceStatusComparer : IEqualityComparer<InstanceServiceStatus>
    {
        public bool Equals(InstanceServiceStatus x, InstanceServiceStatus y)
        {
            return x != null && y != null
                             && x.Name == y.Name
                             && x.MachineName == y.MachineName
                             && x.Status == y.Status
                             && x.Utc.Equals(y.Utc)
                             && x.Version == y.Version;
        }

        public int GetHashCode(InstanceServiceStatus obj)
        {
            throw new NotImplementedException();
        }
    }
}