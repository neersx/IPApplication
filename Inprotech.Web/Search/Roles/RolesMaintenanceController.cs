using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Roles
{
    [Authorize]
    [RoutePrefix("api/roles")]
    [RequiresAccessTo(ApplicationTask.MaintainRole)]
    public class RolesMaintenanceController : ApiController
    {
        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "RoleName",
                SortDir = "asc"
            });

        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        readonly IRoleDetailsService _roleDetailsService;
        readonly IRoleMaintenanceService _roleMaintenanceService;
        readonly IRoleSearchService _roleSearchService;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public RolesMaintenanceController(IRoleSearchService roleSearchService, IPreferredCultureResolver preferredCultureResolver,
                                          IRoleDetailsService roleDetailsService, IDbContext dbContext,
                                          ITaskSecurityProvider taskSecurityProvider, IRoleMaintenanceService roleMaintenanceService)
        {
            _roleSearchService = roleSearchService;
            _preferredCultureResolver = preferredCultureResolver;
            _roleDetailsService = roleDetailsService;
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
            _roleMaintenanceService = roleMaintenanceService;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic GetViewData()
        {
            return new RolePermissionsData
            {
                CanDeleteRole = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRole, ApplicationTaskAccessLevel.Delete),
                CanUpdateRole = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRole, ApplicationTaskAccessLevel.Modify),
                CanCreateRole = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRole, ApplicationTaskAccessLevel.Create),
            };
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        public RoleDetails Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] RolesSearchOptions searchRequest,
                                  [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                  CommonQueryParameters queryParameters = null)
        {
            var details = new RoleDetails();
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var culture = _preferredCultureResolver.Resolve();
            var roles = _roleSearchService.DoSearch(searchRequest, culture);

            var result = roles.Select(_ => new Role
            {
                RoleId = _.Id,
                RoleName = DbFuncs.GetTranslation(_.RoleName, null, _.RoleNameTId, culture),
                Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture),
                IsExternal = _.IsExternal.HasValue && _.IsExternal.Value,
                IsInternal = _.IsExternal.HasValue && !_.IsExternal.Value
            }).ToArray();

            details.Roles = result.OrderByProperty(queryParameters.SortBy,
                                                   queryParameters.SortDir);
            details.Ids = details.Roles.Select(x => x.RoleId);
            return details;
        }

        [HttpGet]
        [Route("search/filterData/column/{field}/role/{roleId}")]
        [NoEnrichment]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(string field,
                                                                               int roleId,
                                                                               [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                                                               TaskSearchCriteria criteria,
                                                                               [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                               CommonQueryParameters queryParameters)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var results = await _roleDetailsService
                .GetTaskDetails(roleId, criteria, queryParameters.Filters.Where(f => !f.Field.IgnoreCaseEquals(field)));

            switch (field.ToUpper())
            {
                case "FEATURE":
                    var featuresList = results.Select(_ => _.Feature)
                                              .Distinct().ToArray();
                    return (from features in featuresList from feature in features select new CodeDescription { Description = feature, Code = feature }).Distinct();
                case "SUBFEATURE":
                    var subFeaturesList = results.Select(_ => _.SubFeature)
                                                 .Distinct().ToArray();
                    return (from subFeatures in subFeaturesList from subFeature in subFeatures select new CodeDescription { Description = subFeature, Code = subFeature }).Distinct();
                case "RELEASE":
                    var releaseVersions = results.Select(_ => _.Release)
                                                 .Distinct().Select(_ => new CodeDescription
                                                 {
                                                     Description = _,
                                                     Code = _
                                                 }).Distinct();
                    return releaseVersions;
            }

            return Enumerable.Empty<CodeDescription>();
        }

        [HttpGet]
        [Route("task-details/{roleId}")]
        [NoEnrichment]
        public async Task<IEnumerable<TaskDetails>> GetTaskDetails(int roleId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] TaskSearchCriteria criteria, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            EnsureRole(roleId);

            return await _roleDetailsService.GetTaskDetails(roleId, criteria, queryParameters.Filters);
        }

        [HttpGet]
        [Route("module-details/{roleId}")]
        [NoEnrichment]
        public async Task<IEnumerable<WebPartDetails>> GetModuleDetails(int roleId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            EnsureRole(roleId);

            return await _roleDetailsService.GetModuleDetails(roleId, queryParameters.Filters);
        }

        [HttpGet]
        [Route("filterData/column/{field}/role/{roleId}")]
        [NoEnrichment]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForModule(string field,
                                                                               int roleId,
                                                                               [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                               CommonQueryParameters queryParameters)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var results = await _roleDetailsService
                .GetModuleDetails(roleId, queryParameters.Filters.Where(f => !f.Field.IgnoreCaseEquals(field)));

            switch (field.ToUpper())
            {
                case "FEATURE":
                    var featuresList = results.Select(_ => _.Feature)
                                              .Distinct().ToArray();
                    return (from features in featuresList from feature in features select new CodeDescription { Description = feature, Code = feature }).Distinct();
                case "SUBFEATURE":
                    var subFeaturesList = results.Select(_ => _.SubFeature)
                                                 .Distinct().ToArray();
                    return (from subFeatures in subFeaturesList from subFeature in subFeatures select new CodeDescription { Description = subFeature, Code = subFeature }).Distinct();
            }

            return Enumerable.Empty<CodeDescription>();
        }

        [HttpGet]
        [Route("subject-details/{roleId}")]
        [NoEnrichment]
        public async Task<IEnumerable<SubjectDetails>> GetSubjectDetails(int roleId)
        {
            EnsureRole(roleId);

            return await _roleDetailsService.GetSubjectDetails(roleId);
        }

        [HttpGet]
        [Route("overview-details/{roleId}")]
        [NoEnrichment]
        public async Task<Role> Get(int roleId)
        {
            EnsureRole(roleId);

            return await _roleDetailsService.Get(roleId);
        }

        void EnsureRole(int roleId)
        {
            var role = _dbContext.Set<InprotechKaizen.Model.Security.Role>()
                                 .SingleOrDefault(_ => _.Id == roleId);

            if (role == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }
        }

        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainRole, ApplicationTaskAccessLevel.Delete)]
        public async Task<RolesDeleteResponseModel> Delete(RolesDeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            return await _roleMaintenanceService.Delete(deleteRequestModel);
        }

        [HttpPost]
        [Route("update")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainRole, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> MaintainRoleDetails(RoleSaveDetails roleSaveDetails)
        {
            if (roleSaveDetails == null)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            var role = _dbContext.Set<InprotechKaizen.Model.Security.Role>()
                                 .SingleOrDefault(_ => _.Id == roleSaveDetails.OverviewDetails.RoleId);
            if (role == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            return await _roleMaintenanceService.MaintainRoleDetails(roleSaveDetails);
        }

        [HttpPost]
        [Route("create")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainRole, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> CreateRole(OverviewDetails overviewDetails)
        {
            return await _roleMaintenanceService.CreateRole(overviewDetails);
        }

        [HttpPost]
        [Route("copy/{roleId}")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainRole, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> CreateDuplicateRole(OverviewDetails overviewDetails, int roleId)
        {
            return await _roleMaintenanceService.DuplicateRole(overviewDetails, roleId);
        }
        public class Role
        {
            public int RoleId { get; set; }
            public string RoleName { get; set; }
            public string Description { get; set; }
            public bool IsExternal { get; set; }
            public bool IsInternal { get; set; }
        }

        public class RoleDetails
        {
            public IEnumerable<Role> Roles { get; set; }
            public IEnumerable<int> Ids { get; set; }
        }

        public class RolePermissionsData
        {
            public bool CanDeleteRole { get; set; }
            public bool CanUpdateRole { get; set; }
            public bool CanCreateRole { get; set; }
        }
    }
}