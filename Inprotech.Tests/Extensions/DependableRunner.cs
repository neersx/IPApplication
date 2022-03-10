using System;
using System.Threading;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Dependable.Dispatcher;
using Dependable.Extensions.Dependencies.Autofac;
using Dependable.Tracking;
using Inprotech.Tests.Dependable;

namespace Inprotech.Tests.Extensions
{
    public static class DependableActivity
    {
        static IScheduler _scheduler;

        public static void Execute(Activity subjectActivity, Func<CompletedActivity, ILifetimeScope> wireup, bool diesOnError = false, Guid? nominatedRoot = null, bool logJobStatusChanged = false, bool detailedLogging = false)
        {
            using (var _event = new ManualResetEvent(false))
            {
                var container = wireup(new CompletedActivity(_event));

                var config = new DependableConfiguration()
                             .SetDefaultRetryCount(1)
                             .SetDefaultRetryDelay(TimeSpan.FromSeconds(1))
                             .SetRetryTimerInterval(TimeSpan.FromSeconds(1))
                             .UseConsoleEventLogger(EventType.JobStatusChanged | EventType.Exception | EventType.JobCancelled)
                             .UseAutofacDependencyResolver(container);

                if (logJobStatusChanged && container.TryResolve(out SimpleLogger trace))
                {
                    config.UseEventSink(new JobStatusEventLogger(trace, detailedLogging));
                }

                _scheduler = config.CreateScheduler();

                var ender = Activity.Run<CompletedActivity>(ca => ca.SetCompleted());
                var onCancel = Activity.Run<CompletedActivity>(ca => ca.SetCompleted());

                var workflow =
                    diesOnError
                        ? Activity
                          .Sequence(subjectActivity, ender)
                          .Cancelled(onCancel)
                          .AnyFailed(ender)
                          .ThenContinue()
                        : Activity
                          .Sequence(subjectActivity, ender)
                          .Cancelled(onCancel)
                          .ThenContinue();

                _scheduler.Start();
                _scheduler.Schedule(workflow, nominatedRoot);

                _event.WaitOne();
            }
        }

        public static bool StopExecutionFor(Guid root)
        {
            return _scheduler.Stop(root);
        }

        public static bool TestException(ExceptionContext ec, string exMessage)
        {
            var ex = ec.Exception;
            while (ex != null && ex.Message != exMessage)
                ex = ex.InnerException;

            return ex != null && ex.Message == exMessage;
        }

        public class CompletedActivity
        {
            readonly ManualResetEvent _event;

            public CompletedActivity(ManualResetEvent @event)
            {
                _event = @event;
            }

            public ExceptionContext ExceptionContext { get; set; }

            public Task SetFailed(ExceptionContext ex)
            {
                ExceptionContext = ex;
                return Task.Run(() => _event.Set());
            }

            public Task SetCompleted()
            {
                return Task.Run(() => _event.Set());
            }
        }
    }
}