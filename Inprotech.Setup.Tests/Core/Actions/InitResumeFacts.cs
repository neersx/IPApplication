using Autofac;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class InitResumeFacts
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
            var container = Substitute.For<IComponentContext>();
            var workflow = new SetupWorkflow(container);
            var cryptoService = Substitute.For<ICryptoService>();
            var ctx = new SetupContext
            {
                InstancePath = "a",
                DatabaseUsername = "user",
                DatabasePassword = "pwd",
                Workflow = workflow,
                IntegrationServerPort = "80"
            };
            var action = new InitResume(SettingsManagerFunc, IisAppInfoManagerFunc, validator, cryptoService);
            var settings = new SetupSettings
            {
                IisSite = "a",
                IisPath = "b",
                RunMode = SetupRunMode.Resume,
                AuthenticationMode = "Forms,Sso",
                IpPlatformSettings = new IpPlatformSettings("something", "something"),
                AdfsSettings = new AdfsSettings {Certificate = "cert", ClientId = "enc", ServerUrl = "http://a.com", RelyingPartyTrustId = "r"},
                CookieConsentSettings = new CookieConsentSettings { CookieConsentBannerHook = "<script />" }
            };
            var iisAppInfo = new IisAppInfo {WebConfig = new WebConfig()};

            settingsManager.Read("a").Returns(settings);
            iisAppManager.Find("a", "b").Returns(iisAppInfo);
            cryptoService.When(x => x.Decrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>())).Do(x => { ((AdfsSettings) x.Args()[1]).ClientId = "cli"; });

            action.Run(ctx, null);

            Assert.Equal(settings, ctx.SetupSettings);
            Assert.Equal(iisAppInfo, ctx.PairedIisApp);
            Assert.Equal(ctx.IpPlatformSettings, settings.IpPlatformSettings);

            cryptoService.ReceivedWithAnyArgs(1).Decrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>());
            Assert.Equal(settings.AdfsSettings.RelyingPartyTrustId, ctx.AdfsSettings.RelyingPartyTrustId);
            Assert.Equal(settings.AdfsSettings.Certificate, ctx.AdfsSettings.Certificate);
            Assert.Equal("cli", ctx.AdfsSettings.ClientId);

            Assert.Equal(ctx.IntegrationServerPort, settings.IntegrationServerPort);
            Assert.Equal(ctx.CookieConsentSettings, settings.CookieConsentSettings);
        }
    }
}