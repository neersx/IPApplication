using System.Threading.Tasks;
using Inprotech.Integration.Settings;
using Inprotech.IntegrationServer.Api.PtoSettings.Epo;
using Inprotech.IntegrationServer.PtoAccess.Epo;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Api.PtoSettings.Epo
{
    public class EpoIntegrationSettingsControllerFacts
    {
        [Fact]
        public async Task TestsSettings()
        {
            var keys = new EpoKeys("a", "b");

            var epoAuthClient = Substitute.For<IEpoAuthClient>();

            epoAuthClient.TestSettings(Arg.Any<EpoKeys>()).Returns(true);

            var subject = new EpoIntegrationSettingsController(epoAuthClient);

            var result = await subject.TestOnly(keys);

            epoAuthClient.Received(1).TestSettings(keys).IgnoreAwaitForNSubstituteAssertion();

            Assert.True(result);
        }
    }
}