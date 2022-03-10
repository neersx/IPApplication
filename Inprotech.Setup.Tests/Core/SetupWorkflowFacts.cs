using Inprotech.Setup.Core;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class SetupWorkflowFacts
    {
        public SetupWorkflowFacts()
        {
            _workflow = new SetupWorkflow(null);
        }

        readonly SetupWorkflow _workflow;

        [Fact]
        public void ShouldAppendAction()
        {
            var action = new DummyAction();
            _workflow.Append(action);

            Assert.Equal(action, _workflow.Peek());
        }

        [Fact]
        public void ShouldClearAll()
        {
            var action = new DummyAction();
            _workflow.Append(action);

            _workflow.Clear();

            Assert.Null(_workflow.Peek());
        }

        [Fact]
        public void ShouldGetNext()
        {
            var action = new DummyAction();
            _workflow.Append(action);

            var next = _workflow.Next();

            Assert.Equal(action, next);

            next = _workflow.Next();

            Assert.Null(next);
        }

        [Fact]
        public void ShouldPrependActions()
        {
            var action1 = new DummyAction();
            var action2 = new DummyAction();
            _workflow.Prepend(new[] {action1, action2});

            Assert.Equal(action1, _workflow.Next());
            Assert.Equal(action2, _workflow.Next());
        }
    }
}