using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    class SystemVersionProvider : IAnalyticsEventProvider
    {
        readonly ISiteControlReader _siteControlReader;

        public SystemVersionProvider(ISiteControlReader siteControlReader)
        {
            _siteControlReader = siteControlReader;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var data = _siteControlReader.ReadMany<string>(SiteControls.DBReleaseVersion, SiteControls.InprotechWebAppsVersion, SiteControls.IntegrationVersion);

            var events = new List<AnalyticsEvent>();
            if (HasValue(data, SiteControls.DBReleaseVersion, AnalyticsEventCategories.VersionDbRelease, out var e)) events.Add(e);
            if (HasValue(data, SiteControls.InprotechWebAppsVersion, AnalyticsEventCategories.VersionInprotechWebApps, out e)) events.Add(e);
            if (HasValue(data, SiteControls.IntegrationVersion, AnalyticsEventCategories.VersionIntegration, out e)) events.Add(e);

            return events;
        }

        bool HasValue(Dictionary<string, string> data, string key, string eventCategory, out AnalyticsEvent @event)
        {
            @event = null;
            var result = data.ContainsKey(key) && !string.IsNullOrEmpty(data[key]);
            if (result)
            {
                @event = new AnalyticsEvent(eventCategory, data[key]);
            }

            return result;
        }
    }
}