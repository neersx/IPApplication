using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Settings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class InstanceInformationFacts
    {
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly IGroupedConfig _aConfig = Substitute.For<IGroupedConfig>();
        readonly IGroupedConfig _bConfig = Substitute.For<IGroupedConfig>();
        readonly IInstancesInfo _instancesInfo = Substitute.For<IInstancesInfo>();

        [Fact]
        public async Task ReturnInstanceInformationFromBothServers()
        {
            var returnData = new[] {new InstanceServiceStatus {Name = "CPAInproDemo-AUS-L-0100", MachineName = "AUS-L-0100", Status = ServiceStatus.Online, Utc = Fixture.TodayUtc(), Version = "v1.0.0"}};

            _instancesInfo.ServerInstances().Returns(returnData);
            _instancesInfo.IntegrationServerInstances().Returns(returnData);

            var path = Fixture.String();
            var subject = new InstanceInformation(_instancesInfo, _fileSystem);

            await subject.Prepare(path);

            var expected = "{\r\n  \"InprotechServer\": [\r\n    {\r\n      \"Name\": \"CPAInproDemo-AUS-L-0100\",\r\n      \"MachineName\": \"AUS-L-0100\",\r\n      \"Version\": \"v1.0.0\",\r\n      \"Status\": \"Online\",\r\n      \"Utc\": \"2000-01-01T00:00:00Z\",\r\n      \"Endpoints\": []\r\n    }\r\n  ],\r\n  \"IntegrationServer\": [\r\n    {\r\n      \"Name\": \"CPAInproDemo-AUS-L-0100\",\r\n      \"MachineName\": \"AUS-L-0100\",\r\n      \"Version\": \"v1.0.0\",\r\n      \"Status\": \"Online\",\r\n      \"Utc\": \"2000-01-01T00:00:00Z\",\r\n      \"Endpoints\": []\r\n    }\r\n  ]\r\n}";

            _fileSystem.Received(1)
                       .WriteAllText(Path.Combine(path, "Instances.json"), expected);
        }
    }
}