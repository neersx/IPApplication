using System.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Profiles
{
    public class HomePageResolver : IHomeStateResolver
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public HomePageResolver(IDbContext dbContext, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public dynamic Resolve()
        {
            var preference = _dbContext.Set<SettingValues>()
                             .SingleOrDefault(s => s.SettingId == KnownSettingIds.AppsHomePage &&
                                                   s.CharacterValue != null &&
                                                   (s.User != null && s.User.Id == _securityContext.User.Id))
                             ?.CharacterValue;
            return !string.IsNullOrEmpty(preference) ? JsonConvert.DeserializeObject(preference) : null;
        }
    }
}
