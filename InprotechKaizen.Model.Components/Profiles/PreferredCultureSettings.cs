using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;

namespace InprotechKaizen.Model.Components.Profiles
{
    public class PreferredCultureSettings : IPreferredCultureSettings
    {
        readonly IDbContext _dbContext;
        readonly ILifetimeScopeCache _perLifetime;
        readonly ISecurityContext _securityContext;

        public PreferredCultureSettings(IDbContext dbContext, ISecurityContext securityContext, ILifetimeScopeCache perLifetime)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _perLifetime = perLifetime;
        }

        public IEnumerable<string> ResolveAll()
        {
            if (_securityContext.User == null)
                return Enumerable.Empty<string>();

            return _perLifetime.GetOrAdd(this,
                                         0,
                                         x =>
                                         {
                                             return _dbContext.Set<SettingValues>()
                                                              .Where(
                                                                     s => s.SettingId == KnownSettingIds.PreferredCulture &&
                                                                          s.CharacterValue != null &&
                                                                          (s.User == null || s.User.Id == _securityContext.User.Id))
                                                              .OrderByDescending(s => s.User.Id)
                                                              .Select(s => s.CharacterValue)
                                                              .ToList();
                                         });
        }
    }
}