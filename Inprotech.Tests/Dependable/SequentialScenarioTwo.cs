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
    public class SequentialScenarioTwoFacts
    {
        readonly SimpleLogger _simpleLogger = new SimpleLogger();
        readonly Bomb _bomb = new Bomb();

        ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
        {
            var builder = new ContainerBuilder();
            builder.RegisterType<SequentialScenarioTwo>().AsSelf();
            builder.RegisterType<FailureHandler>().AsSelf();
            builder.RegisterType<ExceptionFilter>().AsSelf();
            builder.RegisterType<Stop>().AsSelf();
            builder.RegisterInstance(_simpleLogger);
            builder.RegisterInstance(_bomb);
            builder.RegisterInstance(completedActivity).AsSelf();
            return builder.Build();
        }

        [Fact]
        public async Task ScenarioTwoHappyDayChild()
        {
            var expected = @"
SequentialScenarioTwo.RunHandledEach: Begin
SequentialScenarioTwo.Child: Execution of 1 completes.
SequentialScenarioTwo.Child: Execution of 2 completes.
SequentialScenarioTwo.Child: Execution of 3 completes.
Stop.Cleanup: Complete!".Trim();

            var successfulJob = Activity.Run<SequentialScenarioTwo>(s => s.RunHandledEach());

            DependableActivity.Execute(successfulJob, WireUp);

            Assert.True(NormalisedStringComparison.AreSame(expected, _simpleLogger.Collected()));
        }

        [Fact]
        public async Task ScenarioTwoHappyDayParent()
        {
            var expected = @"
SequentialScenarioTwo.RunHandledParent: Begin
SequentialScenarioTwo.Child: Execution of 1 completes.
SequentialScenarioTwo.Child: Execution of 2 completes.
SequentialScenarioTwo.Child: Execution of 3 completes.
Stop.Cleanup: Complete!".Trim();

            var successfulJob = Activity.Run<SequentialScenarioTwo>(s => s.RunHandledParent());

            DependableActivity.Execute(successfulJob, WireUp);

            Assert.True(NormalisedStringComparison.AreSame(expected, _simpleLogger.Collected()));
        }

        [Fact]
        public async Task ScenarioTwoRainyDayChild()
        {
            var expected = @"
SequentialScenarioTwo.RunHandledEach: Begin
SequentialScenarioTwo.Child: Execution of 1 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (1) for Child(1)
SequentialScenarioTwo.Child: Execution of 1 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (1) for Child(1)
FailureHandler.Handle: Handle the failure for 1.
SequentialScenarioTwo.Child: Execution of 2 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (2) for Child(2)
SequentialScenarioTwo.Child: Execution of 2 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (2) for Child(2)
FailureHandler.Handle: Handle the failure for 2.
SequentialScenarioTwo.Child: Execution of 3 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (3) for Child(3)
SequentialScenarioTwo.Child: Execution of 3 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (3) for Child(3)
FailureHandler.Handle: Handle the failure for 3.
Stop.Cleanup: Complete!".Trim();

            var failJob = Activity.Run<SequentialScenarioTwo>(s => s.RunHandledEach());

            _bomb.It();

            DependableActivity.Execute(failJob, WireUp);

            Assert.True(NormalisedStringComparison.AreSame(expected, _simpleLogger.Collected()));
        }

        [Fact]
        public async Task ScenarioTwoRainyDayParent()
        {
            var expected = @"
SequentialScenarioTwo.RunHandledParent: Begin
SequentialScenarioTwo.Child: Execution of 1 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (1) for Child(1)
SequentialScenarioTwo.Child: Execution of 1 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (1) for Child(1)
SequentialScenarioTwo.Child: Execution of 2 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (2) for Child(2)
SequentialScenarioTwo.Child: Execution of 2 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (2) for Child(2)
SequentialScenarioTwo.Child: Execution of 3 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (3) for Child(3)
SequentialScenarioTwo.Child: Execution of 3 throws exception.
ExceptionFilter.LogIncomingException: Log this exception: Oopsie (3) for Child(3)
Stop.Cleanup: Complete!".Trim();

            var failJob = Activity.Run<SequentialScenarioTwo>(s => s.RunHandledParent());

            _bomb.It();

            DependableActivity.Execute(failJob, WireUp);

            Assert.True(NormalisedStringComparison.AreSame(expected, _simpleLogger.Collected()));
        }
    }

    [Collection("Dependable")]
    public class SequentialScenarioTwo
    {
        readonly Bomb _bomb;
        readonly SimpleLogger _simpleLogger;

        public SequentialScenarioTwo(SimpleLogger simpleLogger, Bomb bomb)
        {
            _simpleLogger = simpleLogger;
            _bomb = bomb;
        }

        public async Task<Activity> RunHandledEach()
        {
            var stop = Activity.Run<Stop>(_ => _.Cleanup());

            var workflow = new[] {1, 2, 3}
                .Select(seq => Activity.Run<SequentialScenarioTwo>(_ => _.Child(seq))
                                       .ExceptionFilter<ExceptionFilter>((ex, e) => e.LogIncomingException(ex))
                                       .Failed(Activity.Run<FailureHandler>(_ => _.Handle(seq)))
                                       .ThenContinue());

            _simpleLogger.Write(this, "Begin");

            return Activity.Sequence(workflow)
                           .Then(stop);
        }

        public async Task<Activity> RunHandledParent()
        {
            var stop = Activity.Run<Stop>(_ => _.Cleanup());

            var workflow = new[] {1, 2, 3}
                .Select(seq => Activity.Run<SequentialScenarioTwo>(_ => _.Child(seq)).ThenContinue());

            _simpleLogger.Write(this, "Begin");

            return Activity.Sequence(workflow)
                           .ExceptionFilter<ExceptionFilter>((ex, e) => e.LogIncomingException(ex))
                           .AnyFailed(Activity.Run<FailureHandler>(_ => _.HandleAny()))
                           .Then(stop);
        }

        public async Task Child(int sequence)
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