using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class InitUpdateFacts
    {
        [Fact]
        public void ShouldInitialize()
        {
            var settingsManager = Substitute.For<ISetupSettingsManager>();
            var iisAppManager = Substitute.For<IIisAppInfoManager>();
            
            ISetupSettingsManager SettingsManagerFunc(string privateKey)
            {
                return settingsManager;
            }
            
            IIisAppInfoManager IisAppInfoManagerFunc(string value)
            {
                return iisAppManager;
            }

            var validator = Substitute.For<IValidator>();
            var cryptoService = Substitute.For<ICryptoService>();
            var ctx = new SetupContext
            {
                InstancePath = "a",
                DatabaseUsername = "user",
                DatabasePassword = "pwd",
                StorageLocation = "storage",
                Authentication2FAMode = "Internal",
                AuthenticationMode = "Forms,Sso",
                IpPlatformSettings = new IpPlatformSettings("client", "secret"),
                AdfsSettings = new AdfsSettings {Certificate = "cert", ClientId = "cli", ServerUrl = "http://a.com", RelyingPartyTrustId = "r"},
                IntegrationServerPort = "80",
                CookieConsentSettings = new CookieConsentSettings { CookieConsentBannerHook = "<script />" }
            };

            var action = new InitUpdate(SettingsManagerFunc, validator, IisAppInfoManagerFunc, cryptoService);
            var settings = new SetupSettings
            {
                IisSite = "a",
                IisPath = "b",
                AuthenticationMode = "Windows",
                IpPlatformSettings = new IpPlatformSettings("something else", "something else"),
                AdfsSettings = new AdfsSettings {Certificate = "old", ClientId = "old", ServerUrl = "http://old.com", RelyingPartyTrustId = "r"}
            };

            var iisAppInfo = new IisAppInfo {WebConfig = new WebConfig()};

            settingsManager.Read("a").Returns(settings);
            iisAppManager.Find("a", "b").Returns(iisAppInfo);
            cryptoService.When(x => x.Encrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>())).Do(x => { ((AdfsSettings) x.Args()[1]).ClientId = "enc"; });

            action.Run(ctx, null);

            Assert.Equal(SetupRunMode.Update, settings.RunMode);
            Assert.Equal(SetupStatus.Begin, settings.Status);
            Assert.Equal(ctx.StorageLocation, settings.StorageLocation);
            Assert.Equal(ctx.DatabaseUsername, settings.DatabaseUsername);
            Assert.Equal(ctx.DatabasePassword, settings.DatabasePassword);
            Assert.Equal(ctx.Authentication2FAMode, settings.Authentication2FAMode);
            Assert.Equal(ctx.AuthenticationMode, settings.AuthenticationMode);
            Assert.Equal(ctx.IpPlatformSettings, settings.IpPlatformSettings);

            Assert.Equal("client", ctx.IpPlatformSettings.ClientId);

            cryptoService.ReceivedWithAnyArgs(1).Encrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>());
            Assert.Equal(ctx.AdfsSettings.RelyingPartyTrustId, settings.AdfsSettings.RelyingPartyTrustId);
            Assert.Equal("cert", settings.AdfsSettings.Certificate);
            Assert.Equal("enc", settings.AdfsSettings.ClientId);

            Assert.Equal(ctx.IntegrationServerPort, settings.IntegrationServerPort);
            Assert.Equal(ctx.CookieConsentSettings, settings.CookieConsentSettings);
        }
    }
}