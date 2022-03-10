using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;

namespace Inprotech.IntegrationServer.BackgroundProcessing
{
    public interface IBackgroundTasksProcessor
    {
        Task<BackgroundTaskResult> Process();
    }

    public class BackgroundTasksProcessor<T> : IClock where T : IBackgroundTasksProcessor
    {
        readonly CancellationTokenSource _cts = new CancellationTokenSource();
        readonly ILifetimeScope _lifetimeScope;
        readonly IBackgroundProcessLogger<Clock> _logger;
        readonly IAppSettingsProvider _appSettingsProvider;
        
        public BackgroundTasksProcessor(ILifetimeScope lifetimeScope, IBackgroundProcessLogger<Clock> logger, IAppSettingsProvider appSettingsProvider)
        {
            _lifetimeScope = lifetimeScope;
            _logger = logger;
            _appSettingsProvider = appSettingsProvider;
        }

        public Task Start()
        {
            _ = Task.Run(async () =>
                    {
                        _logger.Trace($"Queue {typeof(T).Name} started");

                        while (!_cts.IsCancellationRequested)
                            try
                            {
                                using (var scope = _lifetimeScope.BeginLifetimeScope())
                                {
                                    LogResult(await scope.Resolve<T>().Process());
                                }
                            }
                            catch (Exception ex)
                            {
                                _logger.Exception(ex);
                            }
                            finally
                            {
                                await Task.Delay(WaitInterval());
                            }
                    }, _cts.Token)
                    .ContinueWith(ex =>
                    {
                        _logger.Information($"Queue {typeof(T).Name} stopped: faulted: {ex.IsFaulted}; cancelled: {ex.IsCanceled}");

                        if (ex.IsFaulted || ex.IsCanceled)
                        {
                            _logger.Exception(ex.Exception);
                        }
                    }, TaskContinuationOptions.OnlyOnFaulted);

            return Task.FromResult((object) null);
        }

        void LogResult(BackgroundTaskResult r)
        {
            if (r.IsInactive)
            {
                _logger.Debug($"Queue {typeof(T).Name} is inactive.");
                return;
            }

            if (r.TotalCompleted == r.TotalFailed && r.TotalCompleted == 0)
                return;
            
            _logger.Information($"Queue {typeof(T).Name} completed {r.TotalCompleted}, failures: {r.TotalFailed}");
        }

        protected virtual TimeSpan WaitInterval()
        {
            return _appSettingsProvider.GetClockInterval();
        }

        public void Stop()
        {
            _logger.Information($"Queue {typeof(T).Name} received stop signal");

            _cts.Cancel();
        }
    }

    public class BackgroundTaskResult
    {
        public BackgroundTaskResult(int totalCompleted, int totalFailed)
        {
            TotalCompleted = totalCompleted;
            TotalFailed = totalFailed;
            IsInactive = false;
        }

        public BackgroundTaskResult(bool isInactive)
        {
            IsInactive = isInactive;
        }

        public bool IsInactive { get; }

        public int TotalCompleted { get; }

        public int TotalFailed { get; }
    }

    public static class HandlerErrorExtensions
    {
        public static string FlattenErrorMessageForFrontEnd(this Exception ex)
        {
            var lines = new List<string>();

            if (ex is AggregateException)
            {
                var flatten = ((AggregateException) ex).Flatten();
                lines.AddRange(flatten.InnerExceptions.Select(e => e.Message));
            }
            else
            {
                lines.Add(ex.Message);
                if (ex.InnerException != null)
                {
                    lines.Add(ex.InnerException.Message);
                }
            }
            
            return string.Join(Environment.NewLine, lines);
        }
    }
}