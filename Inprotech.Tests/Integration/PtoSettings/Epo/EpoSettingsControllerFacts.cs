using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.PtoSettings.Epo;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoSettings.Epo
{
    public class EpoSettingsControllerFacts
    {
        [Fact]
        public async Task PerformsBasicValidationBeforeTesting()
        {
            var epoKeys = new EpoKeys(string.Empty);
            var fixture = new EpoSettingsControllerFixture();
            fixture.EpoIntegrationSettings.Keys.Returns(epoKeys);

            var result = await fixture.Subject.TestOnly(epoKeys);

            Assert.Equal("error", result.Status);

            fixture.IntegrationServerClient.Received(0).Put("api/eposettings", epoKeys).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ReturnsErrorIfTestFails()
        {
            var epoKeys = new EpoKeys("Stark", "Winterfell");
            var fixture = new EpoSettingsControllerFixture();

            fixture.IntegrationServerClient.When(c => c.Put(Arg.Any<string>(), Arg.Any<object>())).Do(x => throw new Exception("Your values are Wrong!"));
            var result = await fixture.Subject.TestAndSave(epoKeys);

            fixture.IntegrationServerClient.Received(1).Put("api/eposettings", epoKeys).IgnoreAwaitForNSubstituteAssertion();
            fixture.EpoIntegrationSettings.Received(0).Keys = epoKeys;

            Assert.Equal("error", result.Status);
        }

        [Fact]
        public void ReturnsMaskedEpoKeys()
        {
            var epoKeys = new EpoKeys("Stark", "Winterfell");
            var fixture = new EpoSettingsControllerFixture();
            fixture.EpoIntegrationSettings.Keys.Returns(epoKeys);

            var result = fixture.Subject.Get();

            Assert.NotNull(result);
            Assert.Equal("*****", result.ConsumerKey);
            Assert.Equal("**********", result.PrivateKey);
        }

        [Fact]
        public async Task SaveReturnsErrorIfDetailsAreNull()
        {
            var fixture = new EpoSettingsControllerFixture();
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await fixture.Subject.TestAndSave(null));
        }

        [Fact]
        public async Task TestReturnsErrorIfDetailsAreNull()
        {
            var fixture = new EpoSettingsControllerFixture();
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await fixture.Subject.TestOnly(null));
        }

        [Fact]
        public async Task TestsAndSavesEpoKeys()
        {
            var epoKeys = new EpoKeys("Stark", "Winterfell");
            var fixture = new EpoSettingsControllerFixture();

            await fixture.Subject.TestAndSave(epoKeys);

            fixture.IntegrationServerClient.Received(1).Put("api/eposettings", epoKeys).IgnoreAwaitForNSubstituteAssertion();
            fixture.EpoIntegrationSettings.Received(1).Keys = epoKeys;
        }

        [Fact]
        public async Task TestsExistingEpoKeys()
        {
            var epoKeys = new EpoKeys("Stark", "Winterfell");

            var fixture = new EpoSettingsControllerFixture();
            fixture.EpoIntegrationSettings.Keys.Returns(epoKeys);

            var result = await fixture.Subject.TestOnly(new EpoKeys());

            fixture.IntegrationServerClient.Received(1).Put("api/eposettings", epoKeys).IgnoreAwaitForNSubstituteAssertion();
            fixture.EpoIntegrationSettings.Received(0).Keys = epoKeys;

            Assert.Equal("success", result.Status);
        }

        [Fact]
        public async Task TestsProvidedEpoKeys()
        {
            var epoKeys = new EpoKeys("Stark", "Winterfell");
            var fixture = new EpoSettingsControllerFixture();

            var result = await fixture.Subject.TestOnly(epoKeys);

            fixture.IntegrationServerClient.Received(1).Put("api/eposettings", epoKeys).IgnoreAwaitForNSubstituteAssertion();
            fixture.EpoIntegrationSettings.Received(0).Keys = epoKeys;

            Assert.Equal("success", result.Status);
        }
    }

    public class EpoSettingsControllerFixture : IFixture<EpoSettingsController>
    {
        public IEpoIntegrationSettings EpoIntegrationSettings = Substitute.For<IEpoIntegrationSettings>();
        public IIntegrationServerClient IntegrationServerClient = Substitute.For<IIntegrationServerClient>();

        public EpoSettingsControllerFixture()
        {
            Subject = new EpoSettingsController(IntegrationServerClient, EpoIntegrationSettings);
        }

        public EpoSettingsController Subject { get; }
    }
}