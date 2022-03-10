using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Threading;
using System.Threading.Tasks;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Analytics;
using Inprotech.Web.Processing;
using InprotechKaizen.Model.Components.Configuration.SiteControl;

namespace Inprotech.Server.Scheduling
{
    public class LowPriorityRunner : IRunner
    {
        static readonly Dictionary<Type, Type> LowPriorityRunnableTypes =
            new Dictionary<Type, Type>
            {
                {typeof(ITranslationChangeMonitor), typeof(IBackgroundProcessLogger<ITranslationChangeMonitor>)},
                {typeof(ISiteControlCacheManager), typeof(IBackgroundProcessLogger<ISiteControlCacheManager>)},
                {typeof(ITrackedEventPersistence), typeof(IBackgroundProcessLogger<ITrackedEventPersistence>)}
            };

        readonly int _errorDelay;
        readonly int _interval;
        readonly ILifetimeScope _lifetimeScope;
        CancellationTokenSource _cancellationTokenSource;

        public LowPriorityRunner(ILifetimeScope lifetimeScope)
        {
            _lifetimeScope = lifetimeScope;
            _interval = 5 * 60 * 1000;
            _errorDelay = _interval * 6;
        }

        public void StartAll()
        {
            StopAll();
            _cancellationTokenSource = new CancellationTokenSource();
            var token = _cancellationTokenSource.Token;

            foreach (var lowPriorityRunnableType in LowPriorityRunnableTypes)
            {
                var logger = (ILogger) _lifetimeScope.Resolve(lowPriorityRunnableType.Value);
                var runnerType = lowPriorityRunnableType.Key;

                _ = Task.Run(async () => { await Start(_lifetimeScope, runnerType, logger, _interval, _errorDelay, token); }, token)
                        .ContinueWith(ex =>
                        {
                            if (ex.IsFaulted || ex.IsCanceled)
                            {
                                logger.Exception(ex.Exception);
                            }
                        }, TaskContinuationOptions.OnlyOnFaulted);
            }
        }

        public void StopAll()
        {
            _cancellationTokenSource?.Cancel();
            _cancellationTokenSource?.Dispose();
        }

        [SuppressMessage("Microsoft.Design", "CA1031:DoNotCatchGeneralExceptionTypes")]
        static async Task Start(ILifetimeScope lifetimeScope, Type runnerType, ILogger logger, int interval, int errorDelay, CancellationToken token)
        {
            logger.Information($"{runnerType.Name} is running");

            var errorDelayCounter = 1;

            while (true)
            {
                if (token.IsCancellationRequested)
                {
                    break;
                }

                await Task.Delay(interval, token);

                using (var scope = lifetimeScope.BeginLifetimeScope())
                {
                    try
                    {
                        var runnable = (IMonitorClockRunnable) scope.Resolve(runnerType);
                        if (runnable is IMonitorClockRunnableAsync clockRunnable)
                        {
                            await clockRunnable.RunAsync();
                        }
                        else
                        {
                            runnable.Run();
                        }

                        errorDelayCounter = 1;
                    }
                    catch (Exception ex)
                    {
                        logger.Exception(ex);

                        await Task.Delay(errorDelay * ++errorDelayCounter, token);
                    }
                }
            }

            logger.Information($"{runnerType.Name} is stopped");
        }
    }
}