using System.Threading.Tasks;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class SetupRunnerFacts
    {
        public SetupRunnerFacts()
        {
            _eventStream = Substitute.For<IEventStream>();
            _setupRunner = new SetupRunner();
        }

        readonly IEventStream _eventStream;
        readonly ISetupRunner _setupRunner;

        [Fact]
        public async Task ShouldCaptureFatalError()
        {
            var workflow = new SetupWorkflow(null);
            var onFailedCalled = false;
            _setupRunner.OnFailed += _ => { onFailedCalled = true; };

            workflow.Append(new ErrorAction());

            var result = await _setupRunner.Run(workflow, _eventStream);

            _eventStream.ReceivedWithAnyArgs().Publish(null);

            Assert.True(onFailedCalled);
            Assert.False(result);
        }

        [Fact]
        public async Task ShouldContinueIfErrorIsNotFatal()
        {
            var workflow = new SetupWorkflow(null);
            var onSuccessCalled = false;
            _setupRunner.OnSuccess += _ => { onSuccessCalled = true; };

            workflow.Append(new ErrorContinueAction());

            var result = await _setupRunner.Run(workflow, _eventStream);
            _eventStream.ReceivedWithAnyArgs().Publish(null);

            Assert.True(onSuccessCalled);
            Assert.True(result);
        }

        [Fact]
        public async Task ShouldInitContext()
        {
            var workflow = new SetupWorkflow(null);
            SetupContext context = null;
            workflow.Context(_ =>
            {
                _["a"] = 1;
                context = _;
            });

            await _setupRunner.Run(workflow, _eventStream);

            Assert.Equal(workflow, context.Workflow);
            Assert.Equal(1, context["a"]);
        }

        [Fact]
        public async Task ShouldInvokePreActionAndPostAction()
        {
            var workflow = new SetupWorkflow(null);
            workflow.Append(new DummyAction());

            var beforeActionCalled = false;
            var afterActionCalled = false;

            _setupRunner.OnBeforeAction += _ => { beforeActionCalled = true; };

            _setupRunner.OnSuccess += _ => { afterActionCalled = true; };

            var result = await _setupRunner.Run(workflow, _eventStream);

            Assert.True(beforeActionCalled);
            Assert.True(afterActionCalled);
            Assert.True(result);
        }
    }
}