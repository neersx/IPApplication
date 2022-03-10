using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.PtoSettings.Uspto;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoSettings.Uspto
{
    public class UsptoTsdrSettingsControllerFacts
    {
        readonly ITsdrIntegrationSettings _tsdrIntegrationSettings = Substitute.For<ITsdrIntegrationSettings>();
        readonly IIntegrationServerClient _integrationServerClient = Substitute.For<IIntegrationServerClient>();

        UsptoTsdrSettingsController CreateSubject()
        {
            return new UsptoTsdrSettingsController(_integrationServerClient, _tsdrIntegrationSettings);
        }

        [Fact]
        public async Task PerformsBasicValidationBeforeTesting()
        {
            var tsdrSecret = new TsdrSecret(string.Empty);

            _tsdrIntegrationSettings.Key.Returns(tsdrSecret.ApiKey);

            var result = await CreateSubject().TestOnly(tsdrSecret);

            Assert.Equal("error", result.Status);

            _integrationServerClient.Received(0).Put("api/tsdrsettings", tsdrSecret).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ReturnsErrorIfTestFails()
        {
            var tsdrSecret = new TsdrSecret("Winterfell");

            _integrationServerClient.When(c => c.Put(Arg.Any<string>(), Arg.Any<object>())).Do(x => throw new Exception("Your values are Wrong!"));
            var result = await CreateSubject().TestAndSave(tsdrSecret);

            _integrationServerClient.Received(1).Put("api/tsdrsettings", tsdrSecret).IgnoreAwaitForNSubstituteAssertion();
            _tsdrIntegrationSettings.Received(0).Key = tsdrSecret.ApiKey;

            Assert.Equal("error", result.Status);
        }

        [Fact]
        public void ReturnsMaskedTsdrSecret()
        {
            var tsdrSecret = new TsdrSecret("Winterfell");
            _tsdrIntegrationSettings.Key.Returns(tsdrSecret.ApiKey);

            var result = CreateSubject().Get();

            Assert.NotNull(result);
            Assert.Equal("**********", result.ApiKey);
        }

        [Fact]
        public async Task SaveReturnsErrorIfDetailsAreNull()
        {
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await CreateSubject().TestAndSave(null));
        }

        [Fact]
        public async Task TestReturnsErrorIfDetailsAreNull()
        {
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await CreateSubject().TestOnly(null));
        }

        [Fact]
        public async Task TestsAndSavesTsdrSecret()
        {
            var tsdrSecret = new TsdrSecret("Winterfell");

            await CreateSubject().TestAndSave(tsdrSecret);

            _integrationServerClient.Received(1).Put("api/tsdrsettings", tsdrSecret).IgnoreAwaitForNSubstituteAssertion();
            _tsdrIntegrationSettings.Received(1).Key = tsdrSecret.ApiKey;
        }

        [Fact]
        public async Task TestsExistingTsdrSecret()
        {
            var tsdrSecret = new TsdrSecret("Winterfell");

            _tsdrIntegrationSettings.Key.Returns(tsdrSecret.ApiKey);

            var result = await CreateSubject().TestOnly(new TsdrSecret());

            _integrationServerClient.Received(1)
                                    .Put("api/tsdrsettings", Arg.Is<TsdrSecret>(_ => _.ApiKey == tsdrSecret.ApiKey))
                                    .IgnoreAwaitForNSubstituteAssertion();
            _tsdrIntegrationSettings.Received(0).Key = tsdrSecret.ApiKey;

            Assert.Equal("success", result.Status);
        }

        [Fact]
        public async Task TestsProvidedTsdrSecret()
        {
            var tsdrSecret = new TsdrSecret("Winterfell");

            var result = await CreateSubject().TestOnly(tsdrSecret);

            _integrationServerClient.Received(1).Put("api/tsdrsettings", tsdrSecret).IgnoreAwaitForNSubstituteAssertion();
            _tsdrIntegrationSettings.Received(0).Key = tsdrSecret.ApiKey;

            Assert.Equal("success", result.Status);
        }
    }
}