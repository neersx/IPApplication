using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    internal class RoleUsersProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;

        public RoleUsersProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            return (await _dbContext.Set<Role>()
                                    .Select(_ => new
                                    {
                                        _.RoleName,
                                        _.Users.Count
                                    })
                                    .ToArrayAsync())
                .Select(_ => new AnalyticsEvent(AnalyticsEventCategories.RolesNoOfUsersPrefix + _.RoleName, _.Count));
        }
    }
}