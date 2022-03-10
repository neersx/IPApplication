using System.Collections.Generic;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Security
{
    public class AuthSettingsResolverFacts
    {
        public AuthSettingsResolverFacts()
        {
            _groupConfig.GetValues(Arg.Any<string[]>()).Returns(new Dictionary<string, string>
            {
                {KnownAppSettingsKeys.AuthenticationMode, "Windows,Forms,c"},
                {KnownAppSettingsKeys.Authentication2FAMode, "External"},
                {KnownAppSettingsKeys.SessionCookieName, "CPA"}
            });
        }

        readonly IGroupedConfig _groupConfig = Substitute.For<IGroupedConfig>();
        readonly IConfigurationSettings _configSettings = Substitute.For<IConfigurationSettings>();

        [Theory]
        [InlineData(null, "a", true)]
        [InlineData("a", null, true)]
        [InlineData(null, null, false)]
        public void ReturnsVerificationConfiguredIfEitherConsentOrPreferenceValueIsSet(string consent, string preference, bool expectation)
        {
            _groupConfig[Arg.Any<string>()].Returns(JsonConvert.SerializeObject(new
            {
                CookieConsentBannerHook = Fixture.String("a"),
                CookieResetConsentHook = Fixture.String("b"),
                CookieConsentVerificationHook = consent,
                PreferenceConsentVerificationHook = preference
            }));

            var r = new AuthSettings();
            AuthSettingsResolver.Resolve(r, x => _groupConfig, _configSettings);

            Assert.True(r.CookieConsentSettings.IsConfigured);
            Assert.True(r.CookieConsentSettings.IsResetConfigured);
            Assert.Equal(expectation, r.CookieConsentSettings.IsVerificationConfigured);
        }

        [Fact]
        public void ReturnsCookieConsentSettings()
        {
            _groupConfig[Arg.Any<string>()].Returns(JsonConvert.SerializeObject(new
            {
                CookieConsentBannerHook = Fixture.String("a"),
                CookieResetConsentHook = Fixture.String("b"),
                CookieConsentVerificationHook = Fixture.String("c")
            }));

            var r = new AuthSettings();
            AuthSettingsResolver.Resolve(r, x => _groupConfig, _configSettings);

            Assert.True(r.CookieConsentSettings.IsConfigured);
            Assert.True(r.CookieConsentSettings.IsResetConfigured);
            Assert.True(r.CookieConsentSettings.IsVerificationConfigured);
        }

        [Fact]
        public void ReturnsEmptyIfCookieScriptNotFOund()
        {
            _groupConfig[Arg.Any<string>()].Returns(JsonConvert.SerializeObject(new
            {
                CookieResetConsentHook = Fixture.String("b"),
                CookieConsentVerificationHook = Fixture.String("c")
            }));

            var r = new AuthSettings();
            AuthSettingsResolver.Resolve(r, x => _groupConfig, _configSettings);

            Assert.False(r.CookieConsentSettings.IsConfigured);
            Assert.False(r.CookieConsentSettings.IsResetConfigured);
            Assert.False(r.CookieConsentSettings.IsVerificationConfigured);
        }

        [Fact]
        public void ReturnsEmptyIfDictionaryDataNotParsed()
        {
            _groupConfig[Arg.Any<string>()].Returns("true");

            var r = new AuthSettings();
            AuthSettingsResolver.Resolve(r, x => _groupConfig, _configSettings);

            Assert.False(r.CookieConsentSettings.IsConfigured);
            Assert.False(r.CookieConsentSettings.IsResetConfigured);
            Assert.False(r.CookieConsentSettings.IsVerificationConfigured);
        }

        [Fact]
        public void ReturnsEmptyIfSettingNotSaved()
        {
            _groupConfig[Arg.Any<string>()].Returns(string.Empty);

            var r = new AuthSettings();
            AuthSettingsResolver.Resolve(r, x => _groupConfig, _configSettings);

            Assert.False(r.CookieConsentSettings.IsConfigured);
            Assert.False(r.CookieConsentSettings.IsResetConfigured);
            Assert.False(r.CookieConsentSettings.IsVerificationConfigured);
        }

        [Fact]
        public void SetsAuthenticationOptions()
        {
            var r = new AuthSettings();
            AuthSettingsResolver.Resolve(r, x => _groupConfig, _configSettings);

            Assert.True(r.WindowsEnabled);
            Assert.True(r.FormsEnabled);
            Assert.True(r.External2FaEnabled);
            Assert.False(r.SsoEnabled);
            Assert.False(r.AdfsEnabled);
            Assert.False(r.Internal2FaEnabled);
            Assert.Equal("CPA", r.SessionCookieName);
        }
    }
}