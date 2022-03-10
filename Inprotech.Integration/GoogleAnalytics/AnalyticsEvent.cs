using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Integration.GoogleAnalytics
{
    public interface IAnalyticsEventProvider
    {
        Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked);
    }

    public class AnalyticsEvent
    {
        public AnalyticsEvent()
        {

        }

        public AnalyticsEvent(string name, string value)
        {
            Name = name;
            Value = value;
        }

        public AnalyticsEvent(string name, object value)
        {
            Name = name;
            Value = value.ToString();
        }

        public string Name { get; set; }

        public string Value { get; set; }
    }
}