using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Integration.DataSources;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;

namespace Inprotech.IntegrationServer.PtoAccess
{
    public interface IThrottler
    {
        Task Delay(TimeSpan? @for = null);

        Task DelayUntilAvailableOrDefault(int siteIdentifier = 0, TimeSpan? @for = null);
    }

    public class Throttler : IThrottler
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly IAvailabilityResolver _availabilityResolver;
        readonly IRuntimeMessages _runtimeMessages;

        public Throttler(IAppSettingsProvider appSettingsProvider, IAvailabilityResolver availabilityResolver, IRuntimeMessages runtimeMessages)
        {
            _appSettingsProvider = appSettingsProvider;
            _availabilityResolver = availabilityResolver;
            _runtimeMessages = runtimeMessages;
        }

        public async Task Delay(TimeSpan? @for = null)
        {
            await Task.Delay(@for ?? _appSettingsProvider.GetActivityDelay());
        }

        public async Task DelayUntilAvailableOrDefault(int siteIdentifier = 0, TimeSpan? @for = null)
        {
            var timeToAvailability = _availabilityResolver.Resolve(siteIdentifier);
            if (timeToAvailability != TimeSpan.Zero)
            {
                var message = $"Entering known external site maintenance window.Download activities will resume after {timeToAvailability.ToString(@"hh\:mm\:ss")}.";

                _runtimeMessages.Display(message);

                await Task.Delay(timeToAvailability);
                return;
            }

            await Delay(@for);
        }
    }
}
