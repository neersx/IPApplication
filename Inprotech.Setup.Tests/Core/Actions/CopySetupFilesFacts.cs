using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class CopySetupFilesFacts
    {
        [Fact]
        public void ShouldCopyFiles()
        {
            var fileSystem = Substitute.For<IFileSystem>();
            var eventStream = Substitute.For<IEventStream>();
            var action = new CopySetupFiles(fileSystem);
            var ctx = new SetupContext();

            ctx.InstancePath = "a";
            action.Run(ctx, eventStream);
            Assert.False(action.ContinueOnException);
            fileSystem.Received().CopyDirectory(Constants.ContentRoot, "a");
        }
    }
}