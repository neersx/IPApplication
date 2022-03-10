using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class FastForwardFacts
    {
        [Fact]
        public void ShouldMoveForwardToLastStatus()
        {
            var workflow = new SetupWorkflow(null);
            workflow.Append(new UpdateStatus(null) {Status = SetupStatus.Begin});
            workflow.Append(new UpdateStatus(null) {Status = SetupStatus.Install});
            workflow.Append(new DummyAction());

            var action = new FastForward();
            var ctx = new SetupContext
            {
                Workflow = workflow,
                SetupSettings = new SetupSettings
                {
                    Status = SetupStatus.Install
                }
            };

            action.Run(ctx, null);
            Assert.IsType<DummyAction>(workflow.Peek());
        }
    }
}