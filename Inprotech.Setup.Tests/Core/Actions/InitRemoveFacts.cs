using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class InitRemoveFacts
    {
        [Fact]
        public void ShouldInitialize()
        {
            var settingsManager = Substitute.For<ISetupSettingsManager>();
            var iisAppInfoManager = Substitute.For<IIisAppInfoManager>();
            
            ISetupSettingsManager SettingsManagerFunc(string privateKey)
            {
                return settingsManager;
            }
            
            IIisAppInfoManager IisAppInfoManagerFunc(string value)
            {
                return iisAppInfoManager;
            }

            var validator = Substitute.For<IValidator>();
            var ctx = new SetupContext();
            var action = new InitRemove(SettingsManagerFunc, validator, IisAppInfoManagerFunc);
            var settings = new SetupSettings();

            ctx.InstancePath = "a";
            settingsManager.Read("a").Returns(settings);

            action.Run(ctx, null);

            Assert.Equal(SetupRunMode.Remove, settings.RunMode);
            Assert.Equal(SetupStatus.Begin, settings.Status);
        }
    }
}