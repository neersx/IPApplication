using System;
using Inprotech.Infrastructure.Hosting;
using Newtonsoft.Json;

namespace Inprotech.Infrastructure.Instrumentation
{
    public interface IApplicationInsights
    {
        void Configure(Action<InstrumentationSettings> set);
        InstrumentationSettings InstrumentationSettings { get; }
    }

    public class ApplicationInsights : IApplicationInsights
    {
        readonly Func<string, IGroupedConfig> _groupedConfig;
        readonly string _hostApplicationName;

        public ApplicationInsights(Func<HostApplication> hostApplication,
                                   Func<string, IGroupedConfig> groupedConfig)
        {
            _groupedConfig = groupedConfig;
            _hostApplicationName = hostApplication().Name;
        }

        public void Configure(Action<InstrumentationSettings> set)
        {
            if (set == null) throw new ArgumentNullException(nameof(set));

            set(InstrumentationSettings);
        }

        public InstrumentationSettings InstrumentationSettings
        {
            get
            {
                var config = _groupedConfig(_hostApplicationName);
                var key = config["InstrumentationKey"];

                if (string.IsNullOrWhiteSpace(key)) return null;

                var settingsData = config["InstrumentationSettings"];
                var settings = settingsData == null ? new InstrumentationSettings() : JsonConvert.DeserializeObject<InstrumentationSettings>(settingsData);
                settings.Key = key;
                return settings;

            }
        }
    }
    public class InstrumentationSettings
    {
        public string Key { get; set; }
        public string ApplicationName { get; set; }
        public bool ExceptionTracking { get; set; }
        public bool SessionTracking { get; set; }
        public bool PerformanceTracking { get; set; }
    }
}