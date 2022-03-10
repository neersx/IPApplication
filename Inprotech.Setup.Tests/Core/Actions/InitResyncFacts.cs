using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class InitResyncFacts
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
            var ctx = new SetupContext
            {
                InstancePath = "a",
                DatabaseUsername = "user",
                DatabasePassword = "pwd",
                IntegrationServerPort = "80"
            };
            var action = new InitResync(SettingsManagerFunc, validator, IisAppInfoManagerFunc);
            var settings = new SetupSettings
            {
                IisSite = "a",
                IisPath = "b",
                AuthenticationMode = "Forms,Sso",
                Authentication2FAMode = "Internal",
                IpPlatformSettings = new IpPlatformSettings("client", "secret")
            };
            var iisAppInfo = new IisAppInfo {WebConfig = new WebConfig()};

            settingsManager.Read("a").Returns(settings);
            iisAppManager.Find("a", "b").Returns(iisAppInfo);

            action.Run(ctx, null);

            Assert.Equal(SetupRunMode.Resync, settings.RunMode);
            Assert.Equal(SetupStatus.Begin, settings.Status);
            Assert.Equal(iisAppInfo, ctx.PairedIisApp);
            Assert.Equal(ctx.DatabaseUsername, settings.DatabaseUsername);
            Assert.Equal(ctx.DatabasePassword, settings.DatabasePassword);
            Assert.Equal(ctx.AuthenticationMode, settings.AuthenticationMode);
            Assert.Equal(ctx.Authentication2FAMode, settings.Authentication2FAMode);
            Assert.Null(ctx.IpPlatformSettings);
            Assert.Equal(ctx.IntegrationServerPort, settings.IntegrationServerPort);
        }
    }
}