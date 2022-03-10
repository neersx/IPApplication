using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    class InstallationDatesProvider : IAnalyticsEventProvider
    {
        const string Format = "yyyy-MM-dd";
        readonly IDbContext _dbContext;

        public InstallationDatesProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {

            var controls = new[] { SiteControls.DBReleaseVersion, SiteControls.InprotechWebAppsVersion, SiteControls.IntegrationVersion };
            var data = await _dbContext.Set<SiteControl>().Where(_ => controls.Contains(_.ControlId)).Select(_ => new { _.ControlId, _.LastChanged })
                                       .ToDictionaryAsync(k => k.ControlId, v => v.LastChanged);

            var events = new List<AnalyticsEvent>();
            if (HasValue(data, SiteControls.DBReleaseVersion, AnalyticsEventCategories.InstallationDateDbRelease, out var e)) events.Add(e);
            if (HasValue(data, SiteControls.InprotechWebAppsVersion, AnalyticsEventCategories.InstallationDateInprotechWebApps, out e)) events.Add(e);
            if (HasValue(data, SiteControls.IntegrationVersion, AnalyticsEventCategories.InstallationDateIntegration, out e)) events.Add(e);

            return events;
        }

        bool HasValue(Dictionary<string, DateTime?> data, string key, string eventCategory, out AnalyticsEvent @event)
        {
            @event = null;
            var result = data.ContainsKey(key) && data[key].HasValue;
            if (result)
            {
                @event = new AnalyticsEvent(eventCategory, data[key].Value.ToString(Format));
            }

            return result;
        }
    }
}