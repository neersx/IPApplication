using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Threading;
using System.Threading.Tasks;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Web.ContentManagement;
using Inprotech.Web.Names.Consolidations;
using Inprotech.Web.Processing;
using Inprotech.Web.Search.Export;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using InprotechKaizen.Model.Components.System.BackgroundProcess;

namespace Inprotech.Server.Scheduling
{
    public class MonitorRunner : IRunner
    {
        static readonly Dictionary<Type, Type> MonitorClockRunnableTypes =
            new Dictionary<Type, Type>
            {
                {typeof(IGlobalNameChangeMonitor), typeof(IBackgroundProcessLogger<IGlobalNameChangeMonitor>)},
                {typeof(IPolicingStatusMonitor), typeof(IBackgroundProcessLogger<IPolicingStatusMonitor>)},
                {typeof(IPolicingDashboardMonitor), typeof(IBackgroundProcessLogger<IPolicingDashboardMonitor>)},
                {typeof(IServiceBrokerStatusMonitor), typeof(IBackgroundProcessLogger<IServiceBrokerStatusMonitor>)},
                {typeof(INameConsolidationStatusMonitor), typeof(IBackgroundProcessLogger<INameConsolidationStatusMonitor>)},
                {typeof(IBackgroundNotificationMonitor), typeof(IBackgroundProcessLogger<IBackgroundNotificationMonitor>)},
                {typeof(IExportContentMonitor), typeof(IBackgroundProcessLogger<IExportContentMonitor>)}
            };

        readonly int _errorDelay;
        readonly int _interval;
        readonly ILifetimeScope _lifetimeScope;
        CancellationTokenSource _cancellationTokenSource;

        public MonitorRunner(ILifetimeScope lifetimeScope,
                             IAppSettingsProvider appSettingsProvider)
        {
            _lifetimeScope = lifetimeScope;
            _interval = int.Parse(appSettingsProvider["MonitorInterval"]) * 1000;
            _errorDelay = _interval * 5;
        }

        public void StartAll()
        {
            StopAll();
            _cancellationTokenSource = new CancellationTokenSource();
            var token = _cancellationTokenSource.Token;

            foreach (var monitorClockRunnableType in MonitorClockRunnableTypes)
            {
                var logger = (ILogger) _lifetimeScope.Resolve(monitorClockRunnableType.Value);
                var runnerType = monitorClockRunnableType.Key;

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
        async Task Start(ILifetimeScope lifetimeScope, Type runnerType, ILogger logger, int interval, int errorDelay, CancellationToken token)
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

                        await Task.Delay(errorDelay * ++errorDelayCounter);
                    }
                }
            }

            logger.Information($"{runnerType.Name} is stopped");
        }
    }
}