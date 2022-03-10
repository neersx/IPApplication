using System;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Inprotech.Tests.Extensions;
using Xunit;

#pragma warning disable 1998

namespace Inprotech.Tests.Dependable
{
    [Collection("Dependable")]
    public class SequentialScenarioOneFacts
    {
        readonly SimpleLogger _simpleLogger = new SimpleLogger();
        readonly Bomb _bomb = new Bomb();

        ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
        {
            var builder = new ContainerBuilder();
            builder.RegisterType<SequentialScenarioOne>().AsSelf();
            builder.RegisterType<FailureHandler>().AsSelf();
            builder.RegisterType<ExceptionFilter>().AsSelf();
            builder.RegisterType<Stop>().AsSelf();
            builder.RegisterInstance(_simpleLogger);
            builder.RegisterInstance(_bomb);
            builder.RegisterInstance(completedActivity).AsSelf();
            return builder.Build();
        }

        [Fact]
        public async Task ScenarioOneHappyDay()
        {
            var expected = @"
SequentialScenarioOne.Run: Begin
SequentialScenarioOne.Child: Scheduling 1
SequentialScenarioOne.GrandChild: Execution of 11 completes.
SequentialScenarioOne.GrandChild: Execution of 12 completes.
SequentialScenarioOne.Child: Scheduling 2
SequentialScenarioOne.GrandChild: Execution of 21 completes.
SequentialScenarioOne.GrandChild: Execution of 22 completes.
Stop.Cleanup: Complete!".Trim();

            var successfulJob = Activity.Run<SequentialScenarioOne>(s => s.Run());

            DependableActivity.Execute(successfulJob, WireUp);

            Assert.True(NormalisedStringComparison.AreSame(expected, _simpleLogger.Collected()));
        }

        [Fact]
        public async Task ScenarioOneRainyDay()
        {
            var expected = @"
SequentialScenarioOne.Run: Begin
SequentialScenarioOne.Child: Scheduling 1
SequentialScenarioOne.GrandChild: Execution of 11 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (11) for GrandChild(11)
SequentialScenarioOne.GrandChild: Execution of 11 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (11) for GrandChild(11)
FailureHandler.Handle: Handle the failure for 11.
SequentialScenarioOne.Child: Scheduling 2
SequentialScenarioOne.GrandChild: Execution of 21 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (21) for GrandChild(21)
SequentialScenarioOne.GrandChild: Execution of 21 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (21) for GrandChild(21)
FailureHandler.Handle: Handle the failure for 21.
Stop.Cleanup: Complete!
".Trim();

            var failJob = Activity.Run<SequentialScenarioOne>(s => s.Run());

            _bomb.It();

            DependableActivity.Execute(failJob, WireUp);

            Assert.True(NormalisedStringComparison.AreSame(expected, _simpleLogger.Collected()));
        }
    }

    [Collection("Dependable")]
    public class SequentialScenarioOne
    {
        readonly Bomb _bomb;
        readonly SimpleLogger _simpleLogger;

        public SequentialScenarioOne(SimpleLogger simpleLogger, Bomb bomb)
        {
            _simpleLogger = simpleLogger;
            _bomb = bomb;
        }

        public async Task<Activity> Run()
        {
            var stop = Activity.Run<Stop>(_ => _.Cleanup());

            var workflow = new[]
            {
                Activity.Run<SequentialScenarioOne>(_ => _.Child(1)),
                Activity.Run<SequentialScenarioOne>(_ => _.Child(2))
            };

            _simpleLogger.Write(this, "Begin");

            return Activity.Sequence(workflow).Then(stop);
        }

        public async Task<Activity> Child(int sequence)
        {
            var workflow = new[]
            {
                sequence * 10 + 1,
                sequence * 10 + 2
            }.Select(seq => Activity.Run<SequentialScenarioOne>(_ => _.GrandChild(seq))
                                    .ExceptionFilter<ExceptionFilter>((ex, e) => e.LogIncomingException(ex))
                                    .Failed(Activity.Run<FailureHandler>(_ => _.Handle(seq))));

            _simpleLogger.Write(this, "Scheduling " + sequence);

            return Activity.Sequence(workflow).ThenContinue();
        }

        public async Task GrandChild(int sequence)
        {
            if (_bomb.IsSet)
            {
                _simpleLogger.Write(this, "Execution of " + sequence + " throws exception.");

                throw new Exception(string.Format("Oopsie ({0})", sequence));
            }

            _simpleLogger.Write(this, "Execution of " + sequence + " completes.");
        }
    }
}