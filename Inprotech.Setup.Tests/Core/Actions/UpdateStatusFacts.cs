using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class UpdateStatusFacts
    {
        [Fact]
        public void ShouldWriteStatusToFile()
        {
            var settingsManager = Substitute.For<ISetupSettingsManager>();

            ISetupSettingsManager SettingsManagerFunc(string privateKey)
            {
                return settingsManager;
            }

            var ctx = new SetupContext();
            var eventStream = Substitute.For<IEventStream>();
            var action = new UpdateStatus(SettingsManagerFunc);
            var settings = new SetupSettings();
            ctx.InstancePath = "a";
            settingsManager.Read("a").Returns(settings);
            action.Status = SetupStatus.Complete;
            action.Run(ctx, eventStream);

            Assert.Equal(SetupStatus.Complete, settings.Status);
            settingsManager.Received().Write("a", settings);
        }
    }
}