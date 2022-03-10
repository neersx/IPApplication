using System;
using System.Globalization;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure.Extensions
{
    public static class AppSettingsProviderExtentions
    {
        public static string GetPrivateKey(this IAppSettingsProvider appSettingsProvider, bool legacy = false)
        {
            return legacy 
                ? appSettingsProvider["LegacyPrivateKey"]
                : appSettingsProvider["PrivateKey"];
        }

        public static TimeSpan GetClockInterval(this IAppSettingsProvider appSettingsProvider)
        {
            return TimeSpan.FromMinutes(double.Parse(appSettingsProvider["ClockInterval"], CultureInfo.InvariantCulture));
        }

        public static TimeSpan GetActivityDelay(this IAppSettingsProvider appSettingsProvider)
        {
            return TimeSpan.FromMinutes(double.Parse(appSettingsProvider["ActivityDelay"], CultureInfo.InvariantCulture));
        }
    }
}