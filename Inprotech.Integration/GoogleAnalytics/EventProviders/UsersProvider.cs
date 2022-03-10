using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    class UsersProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;

        public UsersProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            const string csProvider = "Centura";

            var userIdentity = _dbContext.Set<UserIdentityAccessLog>().Where(_ => _.LastChanged >= lastChecked);

            var web = await userIdentity.Where(_ => _.Provider != csProvider).Select(_ => _.IdentityId).Distinct().CountAsync();
            var clientServer = await userIdentity.Where(_ => _.Provider == csProvider).Select(_ => _.IdentityId).Distinct().CountAsync();
            var active = await userIdentity.Select(_ => _.IdentityId).Distinct().CountAsync();
            var external = await (from u in _dbContext.Set<User>()
                                  join log in userIdentity on u.Id equals log.IdentityId
                                  where u.IsExternalUser
                                  select u.Id
                ).Distinct().CountAsync();

            return new List<AnalyticsEvent>
            {
                new AnalyticsEvent(AnalyticsEventCategories.UsersWeb, web),
                new AnalyticsEvent(AnalyticsEventCategories.UsersClientServer, clientServer),
                new AnalyticsEvent(AnalyticsEventCategories.UsersActive, active),
                new AnalyticsEvent(AnalyticsEventCategories.UsersExternal, external)
            };
        }
    }
}