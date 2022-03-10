using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class InitUpgradeFacts
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

            var webAppManager = Substitute.For<IWebAppInfoManager>();
            var fileSystem = Substitute.For<IFileSystem>();
            var validator = Substitute.For<IValidator>();
            var cryptoService = Substitute.For<ICryptoService>();
            var iisPath = "abc";
            var ctx = new SetupContext
            {
                InstancePath = "a",
                DatabaseUsername = "user",
                DatabasePassword = "pwd",
                NewRootPath = "new-instances",
                AuthenticationMode = "Forms,Sso",
                Authentication2FAMode = "Internal",
                IpPlatformSettings = new IpPlatformSettings("client", "secret"),
                AdfsSettings = new AdfsSettings { Certificate = "cert", ClientId = "cli", ServerUrl = "http://a.com", RelyingPartyTrustId = "r" },
                IntegrationServerPort = "80",
                CookieConsentSettings = new CookieConsentSettings { CookieConsentBannerHook = "<script />" }
            };
            var action = new InitUpgrade(SettingsManagerFunc, webAppManager, validator, IisAppInfoManagerFunc, fileSystem, cryptoService);
            var settings = new SetupSettings
            {
                IisSite = "a",
                IisPath = iisPath
            };
            var iisAppInfo = new IisAppInfo
            {
                VirtualPath = iisPath,
                WebConfig = new WebConfig()
            };
            fileSystem.DirectoryExists(ctx.NewRootPath + "\\a").Returns(true);
            webAppManager.GetNewInstancePath(ctx.NewRootPath, iisPath).Returns("new-instance-1");

            settingsManager.Read("a").Returns(settings);
            iisAppManager.Find("a", iisPath).Returns(iisAppInfo);
            cryptoService.When(x => x.Encrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>())).Do(x => { ((AdfsSettings)x.Args()[1]).ClientId = "enc"; });

            action.Run(ctx, null);

            Assert.Equal(SetupRunMode.Upgrade, settings.RunMode);
            Assert.Equal(SetupStatus.Begin, settings.Status);
            Assert.Equal(iisAppInfo, ctx.PairedIisApp);
            Assert.Equal(ctx.DatabaseUsername, settings.DatabaseUsername);
            Assert.Equal(ctx.DatabasePassword, settings.DatabasePassword);
            Assert.Equal("new-instance-1", ctx.NewInstancePath);
            Assert.Equal("new-instance-1", settings.NewInstancePath);
            Assert.Equal(ctx.AuthenticationMode, settings.AuthenticationMode);
            Assert.Equal(ctx.Authentication2FAMode, settings.Authentication2FAMode);
            Assert.Equal(ctx.IpPlatformSettings, settings.IpPlatformSettings);

            cryptoService.ReceivedWithAnyArgs(1).Encrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>());
            Assert.Equal(ctx.AdfsSettings.RelyingPartyTrustId, settings.AdfsSettings.RelyingPartyTrustId);
            Assert.Equal("cert", settings.AdfsSettings.Certificate);
            Assert.Equal("enc", settings.AdfsSettings.ClientId);

            Assert.Equal(ctx.IntegrationServerPort, settings.IntegrationServerPort);
            Assert.Equal(ctx.CookieConsentSettings, settings.CookieConsentSettings);
        }
    }
}