using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Threading;
using System.Threading.Tasks;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;

namespace Inprotech.Server.Scheduling
{
    public class PriorityRunner : IRunner
    {
        static readonly Dictionary<Type, Type> PriorityRunnableTypes =
            new Dictionary<Type, Type>
            {
                {typeof(IPolicingServerMonitor), typeof(IBackgroundProcessLogger<IPolicingServerMonitor>)},
                {typeof(IPolicingAffectedCasesMonitor), typeof(IBackgroundProcessLogger<IPolicingAffectedCasesMonitor>)}
            };

        readonly int _errorDelay;
        readonly int _interval;
        readonly ILifetimeScope _lifetimeScope;
        CancellationTokenSource _cancellationTokenSource;

        public PriorityRunner(ILifetimeScope lifetimeScope,
                              IAppSettingsProvider appSettingsProvider)
        {
            _lifetimeScope = lifetimeScope;
            _interval = int.Parse(appSettingsProvider["PriorityInterval"]) * 1000;
            _errorDelay = _interval * 5;
        }

        public void StartAll()
        {
            StopAll();
            _cancellationTokenSource = new CancellationTokenSource();
            var token = _cancellationTokenSource.Token;

            foreach (var priorityRunnerType in PriorityRunnableTypes)
            {
                var logger = (ILogger) _lifetimeScope.Resolve(priorityRunnerType.Value);
                var runnerType = priorityRunnerType.Key;

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