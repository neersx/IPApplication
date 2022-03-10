using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Search.Roles
{
    public interface IRoleDetailsService
    {
        Task<IEnumerable<TaskDetails>> GetTaskDetails(int roleId, TaskSearchCriteria criteria, IEnumerable<CommonQueryParameters.FilterValue> filters);
        Task<IEnumerable<WebPartDetails>> GetModuleDetails(int roleId, IEnumerable<CommonQueryParameters.FilterValue> filters);
        Task<IEnumerable<SubjectDetails>> GetSubjectDetails(int roleId);
        Task<RolesMaintenanceController.Role> Get(int roleId);
    }

    public class RoleDetailsService : IRoleDetailsService
    {
        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public RoleDetailsService(IDbContext dbContext, Func<DateTime> clock, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver;
            _clock = clock;
        }

        public async Task<IEnumerable<TaskDetails>> GetTaskDetails(int roleId, TaskSearchCriteria criteria, IEnumerable<CommonQueryParameters.FilterValue> filters)
        {
            var culture = _preferredCultureResolver.Resolve();

            var query = from st in _dbContext.Set<Feature>().SelectMany(_ => _.SecurityTasks)
                        join vot in _dbContext.ValidObjects("TASK", _clock().Date) on st.Id.ToString() equals vot.ObjectIntegerKey into voti
                        from voItems in voti.DefaultIfEmpty()
                        join pd in _dbContext.PermissionData("ROLE", roleId, "TASK", null, null, _clock().Date) on st.Id equals pd.ObjectIntegerKey into pdi
                        from pdItems in pdi.DefaultIfEmpty()
                        join pr in _dbContext.PermissionRule("TASK", null, null) on st.Id equals pr.ObjectIntegerKey
                        join rv in _dbContext.Set<ReleaseVersion>() on st.VersionId equals rv.Id into rvi
                        from rvItems in rvi.DefaultIfEmpty()
                        join r in _dbContext.Set<Role>() on roleId equals r.Id into ri
                        from riItems in ri.DefaultIfEmpty()
                        where riItems != null && st.ProvidedByFeatures.Any(_ => _.IsExternal == riItems.IsExternal || _.IsInternal != riItems.IsExternal) && voItems.ObjectIntegerKey != null
                        select new TaskDetails
                        {
                            RoleKey = roleId,
                            TaskKey = st.Id,
                            TaskName = DbFuncs.GetTranslation(st.Name, null, st.TaskNameTId, culture),
                            Description = DbFuncs.GetTranslation(st.Description, null, st.DescriptionTId, culture),
                            ExecutePermission = pdItems != null ? pdItems.ExecutePermission : null,
                            InsertPermission = pdItems != null ? pdItems.InsertPermission : null,
                            UpdatePermission = pdItems != null ? pdItems.UpdatePermission : null,
                            DeletePermission = pdItems != null ? pdItems.DeletePermission : null,
                            IsExecuteApplicable = pr.ExecutePermission,
                            IsDeleteApplicable = pr.DeletePermission,
                            IsInsertApplicable = pr.InsertPermission,
                            IsUpdateApplicable = pr.UpdatePermission,
                            Feature = st.ProvidedByFeatures.Select(f => f.Category.Name).Distinct(),
                            SubFeature = st.ProvidedByFeatures.Select(f => f.Name).Distinct(),
                            Release = rvItems != null ? rvItems.VersionName : null
                        };

            if (!string.IsNullOrEmpty(criteria.SearchText))
            {
                query = query.Where(_ => _.TaskName.Contains(criteria.SearchText)
                                         || criteria.SearchDescription && _.Description.Contains(criteria.SearchText));
            }

            if (criteria.ShowOnlyPermissionSet)
            {
                query = query.Where(_ => _.ExecutePermission != null && _.ExecutePermission != 0
                                         || _.InsertPermission != null && _.InsertPermission != 0
                                         || _.UpdatePermission != null && _.UpdatePermission != 0
                                         || _.DeletePermission != null && _.DeletePermission != 0);
            }

            foreach (var filter in filters)
            {
                switch (filter.Field.ToUpper())
                {
                    case "FEATURE":
                        var featuresToFilter = filter.Value.Split(',');
                        query = query.OrderBy(_ => _.TaskKey).Where(_ => _.Feature.Any(f => featuresToFilter.Contains(f)));
                        break;
                    case "SUBFEATURE":
                        var subFeaturesToFilter = filter.Value.Split(',');
                        query = query.OrderBy(_ => _.TaskKey).Where(_ => _.SubFeature.Any(sf => subFeaturesToFilter.Contains(sf)));
                        break;
                    case "RELEASE":
                        var releaseVersionsToFilter = filter.Value.Split(',')
                                                            .Select(x => x == "empty" ? null : x.Trim()).ToArray();
                        query = query.OrderBy(_ => _.TaskKey).Where(_ => releaseVersionsToFilter.Contains(_.Release));
                        break;
                }
            }

            var result = await query.OrderBy(_ => _.TaskName).ToArrayAsync();

            return result.AsEnumerable().DistinctBy(_ => _.TaskKey);
        }

        public async Task<IEnumerable<WebPartDetails>> GetModuleDetails(int roleId, IEnumerable<CommonQueryParameters.FilterValue> filters)
        {
            var culture = _preferredCultureResolver.Resolve();

            var query = from wp in _dbContext.Set<Feature>().SelectMany(_ => _.WebpartModules)
                        join vom in _dbContext.ValidObjects("MODULE", _clock().Date) on wp.Id.ToString() equals vom.ObjectIntegerKey into vomi
                        from vomItems in vomi.DefaultIfEmpty()
                        join pd in _dbContext.PermissionData("ROLE", roleId, "MODULE", null, null, _clock().Date) on wp.Id equals pd.ObjectIntegerKey into pdi
                        from pdItems in pdi.DefaultIfEmpty()
                        join r in _dbContext.Set<Role>() on roleId equals r.Id into ri
                        from riItems in ri.DefaultIfEmpty()
                        where riItems != null && wp.ProvidedByFeatures.Any(_ => _.IsExternal == riItems.IsExternal || _.IsInternal != riItems.IsExternal) && vomItems.ObjectIntegerKey != null
                        select new WebPartDetails
                        {
                            RoleKey = roleId,
                            ModuleKey = wp.Id,
                            ModuleTitle = DbFuncs.GetTranslation(wp.Title, null, wp.TitleTId, culture),
                            Description = DbFuncs.GetTranslation(wp.Description, null, wp.DescriptionTId, culture),
                            SelectPermission = pdItems != null ? pdItems.SelectPermission : null,
                            MandatoryPermission = pdItems != null ? pdItems.MandatoryPermission : null,
                            Feature = wp.ProvidedByFeatures.Select(f => f.Category.Name).Distinct(),
                            SubFeature = wp.ProvidedByFeatures.Select(f => f.Name).Distinct()
                        };
            foreach (var filter in filters)
            {
                switch (filter.Field.ToUpper())
                {
                    case "FEATURE":
                        var featuresToFilter = filter.Value.Split(',');
                        query = query.OrderBy(_ => _.ModuleKey).Where(_ => _.Feature.Any(f => featuresToFilter.Contains(f)));
                        break;
                    case "SUBFEATURE":
                        var subFeaturesToFilter = filter.Value.Split(',');
                        query = query.OrderBy(_ => _.ModuleKey).Where(_ => _.SubFeature.Any(sf => subFeaturesToFilter.Contains(sf)));
                        break;
                }
            }

            var result = await query.OrderBy(_ => _.ModuleTitle).ToArrayAsync();

            return result.AsEnumerable().DistinctBy(_ => _.ModuleKey);
        }

        public async Task<IEnumerable<SubjectDetails>> GetSubjectDetails(int roleId)
        {
            var culture = _preferredCultureResolver.Resolve();

            return await (from dt in _dbContext.Set<DataTopic>()
                          join vo in _dbContext.ValidObjects("DATATOPIC", _clock().Date) on dt.Id.ToString() equals vo.ObjectIntegerKey
                          join vor in _dbContext.ValidObjects("DATATOPICREQUIRES", _clock().Date) on dt.Id.ToString() equals vor.ObjectIntegerKey
                          join pd in _dbContext.PermissionData("ROLE", roleId, "DATATOPIC", null, null, _clock().Date) on dt.Id equals pd.ObjectIntegerKey into pdi
                          from pdItems in pdi.DefaultIfEmpty()
                          join r in _dbContext.Set<Role>() on roleId equals r.Id into ri
                          from riItems in ri.DefaultIfEmpty()
                          where riItems != null && vo.ExternalUse == riItems.IsExternal || vo.InternalUse != riItems.IsExternal
                          select new SubjectDetails
                          {
                              RoleKey = roleId,
                              TopicKey = dt.Id,
                              TopicName = DbFuncs.GetTranslation(dt.Name, null, dt.TopicNameTId, culture),
                              Description = DbFuncs.GetTranslation(dt.Description, null, dt.DescriptionTId, culture),
                              SelectPermission = pdItems.SelectPermission ?? 0
                          }).OrderBy(_ => _.TopicName).ToArrayAsync();
        }

        public async Task<RolesMaintenanceController.Role> Get(int roleId)
        {
            var culture = _preferredCultureResolver.Resolve();

            var roleDetails = await _dbContext.Set<Role>()
                                              .Where(_ => _.Id == roleId)
                                              .Select(role => new RolesMaintenanceController.Role
                                              {
                                                  RoleName = DbFuncs.GetTranslation(role.RoleName, null, role.RoleNameTId, culture),
                                                  Description = DbFuncs.GetTranslation(role.Description, null, role.DescriptionTId, culture),
                                                  IsExternal = role.IsExternal.HasValue && role.IsExternal.Value,
                                                  IsInternal = role.IsExternal.HasValue && !role.IsExternal.Value
                                              }).SingleOrDefaultAsync();

            return roleDetails;
        }
    }

    public class TaskDetails : PermissionItem
    {
        public int RoleKey { get; set; }
        public int? TaskKey { get; set; }
        public string TaskName { get; set; }
        public string Description { get; set; }
        public IEnumerable<string> Feature { get; set; }
        public IEnumerable<string> SubFeature { get; set; }
        public string Release { get; set; }
        public byte? IsInsertApplicable { get; set; }
        public byte? IsUpdateApplicable { get; set; }
        public byte? IsDeleteApplicable { get; set; }
        public byte? IsExecuteApplicable { get; set; }
    }

    public class PermissionItem : PermissionsRuleItem
    {
        public string State { get; set; }
        public string ObjectTable { get; set; }
        public string LevelTable { get; set; }
        public short? OldExecutePermission { get; set; }
        public short? OldInsertPermission { get; set; }
        public short? OldDeletePermission { get; set; }
        public short? OldUpdatePermission { get; set; }
        public short? OldSelectPermission { get; set; }
        public short? OldMandatoryPermission { get; set; }
    }

    public class WebPartDetails : PermissionItem
    {
        public int? RoleKey { get; set; }
        public int? ModuleKey { get; set; }
        public string ModuleTitle { get; set; }
        public string Description { get; set; }
        public IEnumerable<string> Feature { get; set; }
        public IEnumerable<string> SubFeature { get; set; }
    }

    public class SubjectDetails : PermissionItem
    {
        public int RoleKey { get; set; }
        public int? TopicKey { get; set; }
        public string TopicName { get; set; }
        public string Description { get; set; }
    }

    public class TaskSearchCriteria
    {
        public string SearchText { get; set; }
        public bool ShowOnlyPermissionSet { get; set; }
        public bool SearchDescription { get; set; }
    }
}