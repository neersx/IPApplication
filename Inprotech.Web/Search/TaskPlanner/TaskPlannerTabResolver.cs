using System.Collections.Concurrent;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.TaskPlanner;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.TaskPlanner;

namespace Inprotech.Web.Search.TaskPlanner
{
    public interface ITaskPlannerTabResolver
    {
        Task<TabData[]> ResolveUserConfiguration();

        Task<bool> InvalidateUserConfiguration();

        Task<TabData[]> ResolveProfileConfiguration();

        Task<bool> Clear();
    }

    public class TaskPlannerTabResolver : ITaskPlannerTabResolver
    {
        static readonly ConcurrentDictionary<int, TabData[]> UsersConfigurationCache = new();

        static readonly ConcurrentDictionary<int, TabData[]> ProfileConfigurationCache = new();
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly int defaultProfileId = -1;

        public TaskPlannerTabResolver(IPreferredCultureResolver preferredCultureResolver, ISecurityContext securityContext, IDbContext dbContext)
        {
            _preferredCultureResolver = preferredCultureResolver;
            _securityContext = securityContext;
            _dbContext = dbContext;
        }

        public async Task<TabData[]> ResolveProfileConfiguration()
        {
            if (ProfileConfigurationCache.TryGetValue(_securityContext.User.Profile?.Id ?? defaultProfileId, out var userProfileConfiguration))
            {
                return userProfileConfiguration;
            }

            var culture = _preferredCultureResolver.Resolve();
            var profileId = _securityContext.User.Profile?.Id;
            var profileTabs = _dbContext.Set<TaskPlannerTabsByProfile>()
                                        .Where(_ => _.ProfileId == profileId)
                                        .Select(x => new { x.TabSequence, x.QueryId, x.IsLocked });

            if (!profileTabs.Any())
            {
                profileTabs = _dbContext.Set<TaskPlannerTabsByProfile>()
                                        .Where(_ => _.ProfileId == null)
                                        .Select(x => new { x.TabSequence, x.QueryId, x.IsLocked });
            }

            userProfileConfiguration = await (from td in profileTabs
                                              join q in _dbContext.Set<Query>().Where(_ => _.ContextId == (int)QueryContext.TaskPlanner)
                                                  on td.QueryId equals q.Id
                                              orderby td.TabSequence
                                              select new TabData
                                              {
                                                  TabSequence = td.TabSequence,
                                                  IsLocked = td.IsLocked,
                                                  SavedSearch = new QueryData
                                                  {
                                                      Key = td.QueryId,
                                                      SearchName = DbFuncs.GetTranslation(q.Name, null, null, culture),
                                                      Description = DbFuncs.GetTranslation(q.Description, null, null, culture)
                                                  }
                                              }).ToArrayAsync();

            ProfileConfigurationCache.AddOrUpdate(_securityContext.User.Profile?.Id ?? defaultProfileId,
                                                  userProfileConfiguration,
                                                  (k, v) =>
                                                  {
                                                      v = userProfileConfiguration;
                                                      return v;
                                                  });

            return userProfileConfiguration;
        }

        public Task<bool> Clear()
        {
            ProfileConfigurationCache.Clear();
            UsersConfigurationCache.Clear();
            return Task.FromResult(true);
        }
        
        public async Task<TabData[]> ResolveUserConfiguration()
        {
            var culture = _preferredCultureResolver.Resolve();

            if (UsersConfigurationCache.TryGetValue(_securityContext.User.Id, out var usersTabConfigurations))
            {
                return usersTabConfigurations;
            }

            var userTabs = _dbContext.Set<TaskPlannerTab>()
                                     .Where(_ => _.IdentityId == _securityContext.User.Id)
                                     .Select(x => new { x.TabSequence, x.QueryId, x.IdentityId });

            var profileId = _securityContext.User.Profile?.Id;
            var profileTabs = _dbContext.Set<TaskPlannerTabsByProfile>()
                                        .Where(_ => _.ProfileId == profileId)
                                        .Select(x => new { x.TabSequence, x.QueryId, x.IsLocked });

            if (!profileTabs.Any())
            {
                profileTabs = _dbContext.Set<TaskPlannerTabsByProfile>()
                                        .Where(_ => _.ProfileId == null)
                                        .Select(x => new { x.TabSequence, x.QueryId, x.IsLocked });
            }

            var tabsData = from pt in profileTabs
                           join ut in userTabs on pt.TabSequence equals ut.TabSequence into up
                           from ut in up.DefaultIfEmpty()
                           select new
                           {
                               pt.TabSequence,
                               QueryId = pt.IsLocked || ut == null ? pt.QueryId : ut.QueryId,
                               pt.IsLocked
                           };

            var userTabConfiguration = await (from td in tabsData
                                              join q in _dbContext.Set<Query>().Where(_ => _.ContextId == (int)QueryContext.TaskPlanner)
                                                  on td.QueryId equals q.Id
                                              orderby td.TabSequence
                                              select new TabData
                                              {
                                                  TabSequence = td.TabSequence,
                                                  IsLocked = td.IsLocked,
                                                  SavedSearch = new QueryData
                                                  {
                                                      Key = td.QueryId,
                                                      SearchName = DbFuncs.GetTranslation(q.Name, null, null, culture),
                                                      Description = DbFuncs.GetTranslation(q.Description, null, null, culture),
                                                      IsPublic = q.IdentityId == null,
                                                      TabSequence = td.TabSequence,
                                                      PresentationId = q.PresentationId
                                                  },
                                                  
                                              }).ToArrayAsync();

            UsersConfigurationCache.AddOrUpdate(_securityContext.User.Id,
                                                userTabConfiguration,
                                                (k, v) =>
                                                {
                                                    v = userTabConfiguration;
                                                    return v;
                                                });

            return userTabConfiguration;
        }

        public Task<bool> InvalidateUserConfiguration()
        {
            var hasRemoved = UsersConfigurationCache.TryRemove(_securityContext.User.Id, out var usersTabConfigurations);
            return Task.FromResult(hasRemoved);
        }
        
    }
}