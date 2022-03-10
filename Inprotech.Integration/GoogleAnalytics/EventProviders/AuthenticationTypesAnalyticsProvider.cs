using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    class AuthenticationTypesAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;

        public AuthenticationTypesAnalyticsProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var userIdentity = _dbContext.Set<UserIdentityAccessLog>().Where(_ => _.LastChanged >= lastChecked);

            var data = await userIdentity.GroupBy(k => k.Provider).Select(_ => new
            {
                _.Key,
                Total = _.Count()
            }).ToDictionaryAsync(k => k.Key, v => v.Total);

            var events = new List<AnalyticsEvent>();
            foreach (var d in data)
            {
                events.Add(new AnalyticsEvent(AnalyticsEventCategories.AuthenticationTypesPrefix + d.Key, d.Value));
            }

            return events;
        }
    }
}