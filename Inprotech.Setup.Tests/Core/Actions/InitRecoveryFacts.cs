using Inprotech.Setup.Actions;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class InitRecoveryFacts
    {
        [Fact]
        public void ShouldInitialize()
        {
            var settingsManger = Substitute.For<ISetupSettingsManager>();
            var iisAppManager = Substitute.For<IIisAppInfoManager>();
            
            ISetupSettingsManager SettingsManagerFunc(string privateKey)
            {
                return settingsManger;
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
                AuthenticationMode = "Forms,Sso",
                Authentication2FAMode = "Internal",
                IpPlatformSettings = new IpPlatformSettings("client", "secret"),
                ["failedAction"] = typeof(ApplyInprotechDatabaseChanges).Name
            };
            var action = new InitRecovery(SettingsManagerFunc, validator, IisAppInfoManagerFunc);
            var settings = new SetupSettings
            {
                IisSite = "a",
                IisPath = "b"
            };
            var iisAppInfo = new IisAppInfo {WebConfig = new WebConfig()};

            settingsManger.Read("a").Returns(settings);
            iisAppManager.Find("a", "b").Returns(iisAppInfo);

            action.Run(ctx, null);

            Assert.Equal(SetupRunMode.Recovery, settings.RunMode);
            Assert.Equal(SetupStatus.Begin, settings.Status);
            Assert.Equal(iisAppInfo, ctx.PairedIisApp);
            Assert.Equal(ctx.DatabaseUsername, settings.DatabaseUsername);
            Assert.Equal(ctx.DatabasePassword, settings.DatabasePassword);
            Assert.Equal(ctx.Authentication2FAMode, settings.Authentication2FAMode);
            Assert.Equal(ctx.AuthenticationMode, settings.AuthenticationMode);
            Assert.Equal(ctx.IpPlatformSettings, settings.IpPlatformSettings);
        }
    }
}