using System;
using System.Threading.Tasks;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.IntegrationServer.Jobs;
using Inprotech.IntegrationServer.Scheduling;

namespace Inprotech.IntegrationServer.BackgroundProcessing
{
    public interface IClock
    {
        Task Start();

        void Stop();
    }

    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design",
        "CA1001:TypesThatOwnDisposableFieldsShouldBeDisposable")]
    public class Clock : IClock
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly ILifetimeScope _lifetimeScope;
        readonly IBackgroundProcessLogger<Clock> _logger;

        static bool _stopRequested = false;

        public Clock(ILifetimeScope lifetimeScope, IAppSettingsProvider appSettingsProvider,
                     IBackgroundProcessLogger<Clock> logger)
        {
            _lifetimeScope = lifetimeScope;
            _appSettingsProvider = appSettingsProvider;
            _logger = logger;
        }

        public async Task Start()
        {
            _stopRequested = false;

            var interval = TimeSpan.FromMilliseconds((long) _appSettingsProvider.GetClockInterval().TotalMilliseconds);

            while (!_stopRequested)
            {
                await GetService<PendingScheduleInterrupter>(async t => await t.Interrupt());

                await GetService<PendingJobsInterrupter>(async t => await t.Interrupt());

                await Task.Delay(interval);
            }
        }

        public void Stop()
        {
            _stopRequested = true;
        }

        async Task GetService<T>(Func<T, Task> run) where T : IInterrupter
        {
            try
            {
                using (var scope = _lifetimeScope.BeginLifetimeScope())
                {
                    var type = typeof (T);
                    var handler = scope.ResolveNamed<IInterrupter>(type.Name);
                    await run((T) handler);
                }
            }
            catch (Exception ex)
            {
                _logger.Exception(ex);
            }
        }
    }
}