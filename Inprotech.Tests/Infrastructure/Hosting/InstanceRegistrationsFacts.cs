using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Hosting
{
    public class InstanceRegistrationsFacts
    {
        readonly IAppSettingsProvider _appSettingsProvider = Substitute.For<IAppSettingsProvider>();
        readonly IGroupedConfig _groupedConfig = Substitute.For<IGroupedConfig>();
        readonly string _hostApplicationName = Fixture.String();
        readonly string _instanceName = Fixture.String();

        [Theory]
        [InlineData(ServiceStatus.Online)]
        [InlineData(ServiceStatus.Offline)]
        public void ShouldSetDetailsAccordingly(ServiceStatus serviceStatus)
        {
            _appSettingsProvider["InstanceName"].Returns(_instanceName);

            new InstanceRegistrations(HostApplication, GroupedConfig, Fixture.Today, _appSettingsProvider)
                .RegisterSelf(serviceStatus, new string[0]);

            _groupedConfig.Received(1).SetValue("Instances",
                                                Arg.Is<string>(_ => JsonConvert.DeserializeObject<IEnumerable<InstanceServiceStatus>>(_)
                                                                               .Single().Status == serviceStatus));

            _groupedConfig.Received(1).SetValue("Instances",
                                                Arg.Is<string>(_ => JsonConvert.DeserializeObject<IEnumerable<InstanceServiceStatus>>(_)
                                                                               .Single().MachineName == Environment.MachineName));

            _groupedConfig.Received(1).SetValue("Instances",
                                                Arg.Is<string>(_ => JsonConvert.DeserializeObject<IEnumerable<InstanceServiceStatus>>(_)
                                                                               .Single().Name == _instanceName));

            _groupedConfig.Received(1).SetValue("Instances",
                                                Arg.Is<string>(_ => JsonConvert.DeserializeObject<IEnumerable<InstanceServiceStatus>>(_)
                                                                               .Single().Utc == Fixture.Today().ToUniversalTime()));
        }

        HostApplication HostApplication()
        {
            return new HostApplication(_hostApplicationName);
        }

        IGroupedConfig GroupedConfig(string hostApplicationName)
        {
            return _groupedConfig;
        }

        [Fact]
        public void ShouldPersistToTheTargetInstance()
        {
            var allInstances = new[]
            {
                new
                {
                    MachineName = "abc",
                    Name = "instance@abc",
                    Status = ServiceStatus.Online
                },
                new
                {
                    MachineName = "def",
                    Name = _instanceName,
                    Status = ServiceStatus.Online
                },
                new
                {
                    MachineName = "ghi",
                    Name = "instance@ghi",
                    Status = ServiceStatus.Online
                }
            };

            _appSettingsProvider["InstanceName"].Returns(_instanceName);

            _groupedConfig["Instances"].Returns(JsonConvert.SerializeObject(allInstances));

            new InstanceRegistrations(HostApplication, GroupedConfig, Fixture.Today, _appSettingsProvider)
                .RegisterSelf(ServiceStatus.Offline, new string[0]);

            _groupedConfig.Received(1).SetValue("Instances",
                                                Arg.Is<string>(_ => JsonConvert.DeserializeObject<IEnumerable<InstanceServiceStatus>>(_)
                                                                               .ByName(_instanceName).Status == ServiceStatus.Offline));
            _groupedConfig.Received(1).SetValue("Instances",
                                                Arg.Is<string>(_ => JsonConvert.DeserializeObject<IEnumerable<InstanceServiceStatus>>(_)
                                                                               .ByName("instance@abc").Status == ServiceStatus.Online));
            _groupedConfig.Received(1).SetValue("Instances",
                                                Arg.Is<string>(_ => JsonConvert.DeserializeObject<IEnumerable<InstanceServiceStatus>>(_)
                                                                               .ByName("instance@ghi").Status == ServiceStatus.Online));
        }
    }
}