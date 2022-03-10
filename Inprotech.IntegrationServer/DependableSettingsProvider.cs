using System;
using Inprotech.Contracts;
using Inprotech.Contracts.Settings;
using Inprotech.Integration.Settings;

namespace Inprotech.IntegrationServer
{
    public interface IDependableSettings
    {
        DependableSettings GetSettings();
    }

    public class DependableSettingsProvider : IDependableSettings
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly IGroupedSettings _dependableSettings;

        public DependableSettingsProvider(GroupedConfigSettings.Factory settings, IAppSettingsProvider appSettingsProvider)
        {
            _appSettingsProvider = appSettingsProvider;
            _dependableSettings = settings("Dependable");
        }

        public DependableSettings GetSettings()
        {
            var retryTimerInterval = _dependableSettings.GetValueOrDefault<double?>("RetryTimerInterval")
                                     ?? double.Parse(_appSettingsProvider["RetryTimerInterval"]);

            var retryCount = _dependableSettings.GetValueOrDefault<int?>("RetryCount")
                             ?? int.Parse(_appSettingsProvider["RetryCount"]);

            var defaultRetryDelay = _dependableSettings.GetValueOrDefault<double?>("RetryDelay")
                                    ?? double.Parse(_appSettingsProvider["RetryDelay"]);

            var dmsIntegrationRetryDelay = _dependableSettings.GetValueOrDefault<double?>("RetryDelay")
                                           ?? double.Parse(_appSettingsProvider["RetryDelay"]);

            return new DependableSettings
                   {
                       RetryTimerInterval = TimeSpan.FromMinutes(retryTimerInterval),
                       RetryCount = retryCount,
                       RetryDelay = TimeSpan.FromMinutes(defaultRetryDelay),
                       DmsRetryDelay = TimeSpan.FromMinutes(dmsIntegrationRetryDelay)
                   };
        }
    }

    public class DependableSettings
    {
        public TimeSpan RetryTimerInterval { get; set; }

        public TimeSpan DmsRetryDelay { get; set; }

        public TimeSpan RetryDelay { get; set; }

        public int RetryCount { get; set; }
    }
}