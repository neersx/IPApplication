using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Search.TaskPlanner;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.TaskPlanner;

namespace Inprotech.Web.Configuration.TaskPlanner
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/taskPlannerConfiguration")]
    [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerConfiguration)]
    public class TaskPlannerConfigurationController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ITaskPlannerTabResolver _taskPlannerTabResolver;

        public TaskPlannerConfigurationController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ITaskPlannerTabResolver taskPlannerTabResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _taskPlannerTabResolver = taskPlannerTabResolver;
        }

        [HttpGet]
        [Route("")]
        [NoEnrichment]
        public async Task<List<TaskPlannerTabConfigItem>> Search()
        {
            var tabData = await (from t in _dbContext.Set<TaskPlannerTabsByProfile>()
                                 join p in _dbContext.Set<Profile>() on t.ProfileId equals p.Id into pt
                                 from p in pt.DefaultIfEmpty()
                                 join q in _dbContext.Set<Query>() on t.QueryId equals q.Id
                                 orderby t.ProfileId, t.TabSequence
                                 select new { t.Id, Profile = p, t.QueryId, QueryName = q.Name, t.TabSequence, t.IsLocked }).ToListAsync();

            var culture = _preferredCultureResolver.Resolve();
            var list = (from t in tabData
                        group t by new { t.Profile }
                        into g
                        let tab1 = g.Single(x => x.TabSequence == 1)
                        let tab2 = g.Single(x => x.TabSequence == 2)
                        let tab3 = g.Single(x => x.TabSequence == 3)
                        select new TaskPlannerTabConfigItem
                        {
                            Id = tab1.Id,
                            Profile = g.Key.Profile != null ? new ProfileData { Key = g.Key.Profile.Id, Name = g.Key.Profile.Name } : null,
                            Tab1 = new QueryData { Key = tab1.QueryId, SearchName = DbFuncs.GetTranslation(tab1.QueryName, null, null, culture) },
                            Tab2 = new QueryData { Key = tab2.QueryId, SearchName = DbFuncs.GetTranslation(tab2.QueryName, null, null, culture) },
                            Tab3 = new QueryData { Key = tab3.QueryId, SearchName = DbFuncs.GetTranslation(tab3.QueryName, null, null, culture) },
                            Tab1Locked = tab1.IsLocked,
                            Tab2Locked = tab2.IsLocked,
                            Tab3Locked = tab3.IsLocked
                        }
                ).OrderBy(_ => _.Profile?.Name).ToList();

            return list;
        }

        [HttpPost]
        [Route("save")]
        public async Task<bool> Save(List<TaskPlannerTabConfigItem> configs)
        {
            if (configs == null || !configs.Any())
            {
                throw new ArgumentNullException(nameof(configs));
            }

            var profileIds = configs.Select(x => x.Profile?.Key).ToList();
            var tabIdsToBeRemoved = configs.Where(x => x.Id.HasValue).Select(x => x.Id).ToList();

            profileIds.AddRange(_dbContext.Set<TaskPlannerTabsByProfile>()
                                          .Where(_ => tabIdsToBeRemoved.Contains(_.Id)).Select(_ => _.ProfileId));

            var itemsToBeRemoved = _dbContext.Set<TaskPlannerTabsByProfile>()
                                             .Where(_ => profileIds.Contains(_.ProfileId));
            _dbContext.RemoveRange(itemsToBeRemoved);

            var profilesTabSequences = new List<TaskPlannerTabsByProfile>();
            foreach (var config in configs.Where(_ => !_.IsDeleted))
            {
                var profileId = config.Profile?.Key;
                profilesTabSequences.Add(new TaskPlannerTabsByProfile(profileId, config.Tab1.Key, 1) { IsLocked = config.Tab1Locked });
                profilesTabSequences.Add(new TaskPlannerTabsByProfile(profileId, config.Tab2.Key, 2) { IsLocked = config.Tab2Locked });
                profilesTabSequences.Add(new TaskPlannerTabsByProfile(profileId, config.Tab3.Key, 3) { IsLocked = config.Tab3Locked });
            }

            _dbContext.AddRange(profilesTabSequences);
            await _dbContext.SaveChangesAsync();
            await _taskPlannerTabResolver.Clear();

            return true;
        }
    }
}