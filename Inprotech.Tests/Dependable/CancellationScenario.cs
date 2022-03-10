using System;
using System.ComponentModel;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Inprotech.Tests.Extensions;
using Xunit;
using static System.Threading.Thread;

#pragma warning disable 1998

namespace Inprotech.Tests.Dependable
{
    [Collection("Dependable")]
    public class CancellationScenarioFacts
    {
        readonly SimpleLogger _simpleLogger = new SimpleLogger();
        readonly Canceller _canceller = new Canceller();
        bool _cancelRequested;

        ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
        {
            var builder = new ContainerBuilder();

            builder.RegisterType<CancellationScenario>().AsSelf();
            builder.RegisterType<Stop>().AsSelf();
            builder.RegisterInstance(_simpleLogger);
            builder.RegisterInstance(completedActivity).AsSelf();
            builder.RegisterInstance(_canceller);
            return builder.Build();
        }

        [Fact]
        public async Task CallsConfiguredOnCancelledActivity()
        {
            var rootId = Guid.NewGuid();
            var expected = @"CancellationScenario.Run: Begin
CancellationScenario.Quick: Execution of 1 completes.
CancellationScenario.LongRunning: Execution of 2 completes.
CancellationScenario.CancelCompensation: Execution of Cancellation Compensation";

            var cancelTask = Task.Run(() =>
            {
                Sleep(TimeSpan.FromMilliseconds(1000));
                _cancelRequested = true;
            });

            _canceller.OnCancelRequested += (s, e) =>
            {
                var stopInitiated = DependableActivity.StopExecutionFor(rootId);
                Assert.True(stopInitiated);
            };

            _canceller.OnRequestCancellationStatus += (s, e) => { e.Cancel = _cancelRequested; };

            var job = Activity.Run<CancellationScenario>(s => s.Run());

            var dependableTask = Task.Run(() => { DependableActivity.Execute(job, WireUp, false, rootId); });

            Task.WaitAll(cancelTask, dependableTask);

            var result = _simpleLogger.Collected();

            Assert.Equal(NormalisedStringComparison.Normalize(expected), NormalisedStringComparison.Normalize(result));
        }

        [Fact]
        public async Task DoesNotCallOnCancelledActivityIfDoesNotGetCancelled()
        {
            var rootId = Guid.NewGuid();
            var expected = @"CancellationScenario.RunQuickly: Begin
CancellationScenario.Quick: Execution of 1 completes.
CancellationScenario.Quick: Execution of 2 completes.
CancellationScenario.Quick: Execution of 3 completes.";

            var job = Activity.Run<CancellationScenario>(s => s.RunQuickly());

            DependableActivity.Execute(job, WireUp, false, rootId);
            DependableActivity.StopExecutionFor(rootId);

            var result = _simpleLogger.Collected();
            Assert.True(NormalisedStringComparison.AreSame(expected, result));
        }
    }

    public class Canceller
    {
        public EventHandler OnCancelRequested;

        public EventHandler<CancelEventArgs> OnRequestCancellationStatus;

        public void Cancel()
        {
            OnCancelRequested?.Invoke(this, EventArgs.Empty);
        }

        public bool ShouldCancelNow()
        {
            var e = new CancelEventArgs();

            OnRequestCancellationStatus?.Invoke(this, e);

            return e.Cancel;
        }
    }

    public class CancellationScenario
    {
        readonly Canceller _canceller;
        readonly SimpleLogger _simpleLogger;

        public CancellationScenario(SimpleLogger simpleLogger, Canceller canceller)
        {
            _simpleLogger = simpleLogger;
            _canceller = canceller;
        }

        public Task<Activity> Run()
        {
            var workflow = new[]
            {
                Activity.Run<CancellationScenario>(_ => _.Quick(1)),
                Activity.Run<CancellationScenario>(_ => _.LongRunning(2)),
                Activity.Run<CancellationScenario>(_ => _.Quick(3))
            };

            _simpleLogger.Write(this, "Begin");

            return Task.FromResult<Activity>(Activity.Sequence(workflow)
                                                     .Cancelled(Activity.Run<CancellationScenario>(_ => _.CancelCompensation())));
        }

        public Task<Activity> RunQuickly()
        {
            var workflow = new[]
            {
                Activity.Run<CancellationScenario>(_ => _.Quick(1)),
                Activity.Run<CancellationScenario>(_ => _.Quick(2)),
                Activity.Run<CancellationScenario>(_ => _.Quick(3))
            };

            _simpleLogger.Write(this, "Begin");

            return Task.FromResult<Activity>(Activity.Sequence(workflow)
                                                     .Cancelled(Activity.Run<CancellationScenario>(_ => _.CancelCompensation())));
        }

        public async Task LongRunning(int sequence)
        {
            var isCancel = false;
            while (isCancel == false)
            {
                Sleep(TimeSpan.FromMilliseconds(100));
                isCancel = _canceller.ShouldCancelNow();

                if (isCancel)
                {
                    _canceller.Cancel();
                }
            }

            _simpleLogger.Write(this, "Execution of " + sequence + " completes.");
        }

        public async Task Quick(int sequence)
        {
            _simpleLogger.Write(this, "Execution of " + sequence + " completes.");
        }

        public async Task CancelCompensation()
        {
            _simpleLogger.Write(this, "Execution of Cancellation Compensation");
        }
    }
}