using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.Checklists;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Rules.Checklists
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Delete)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Delete)]
    [RequiresAccessTo(ApplicationTask.MaintainQuestion)]
    [RoutePrefix("api/configuration/rules/checklist-configuration")]
    public class ChecklistConfigurationSearchController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ICommonQueryService _commonQueryService;
        readonly IChecklistConfigurationSearch _checklistConfigurationSearch;

        public ChecklistConfigurationSearchController(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider, ICommonQueryService commonQueryService, IChecklistConfigurationSearch checklistConfigurationSearch)
        {
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
            _commonQueryService = commonQueryService;
            _checklistConfigurationSearch = checklistConfigurationSearch;
        }

        [Route("view")]
        [HttpGet]
        public dynamic GetViewData()
        {
            return new
            {
                CanMaintainProtectedRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules),
                CanMaintainRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules),
                CanMaintainQuestion = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainQuestion),
                HasOffices = _dbContext.Set<Office>().Any(),
                CanAddProtectedRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create),
                CanAddRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Create)
            };
        }

        [HttpGet]
        [Route("search")]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] SearchCriteria filter,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            queryParameters ??= new CommonQueryParameters();

            if (filter.MatchType == CriteriaMatchOptions.BestCriteriaOnly)
            {
                queryParameters.Take = 1;
                queryParameters.Skip = 0;
                queryParameters.SortBy = null;
                queryParameters.Filters = queryParameters.Filters;
            }

            var result = _commonQueryService.Filter(_checklistConfigurationSearch.Search(filter), queryParameters);
            
            var orderedResults = filter.MatchType == CriteriaMatchOptions.BestCriteriaOnly
                ? result : result.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                                 .ThenByDescending(x => x.BestFit);

            return GetPagedResults(orderedResults, queryParameters);
        }

        [HttpGet]
        [Route("searchByIds")]
        public dynamic SearchByIds([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "ids")] int[] ids,
                                   [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            var result = _commonQueryService.Filter(_checklistConfigurationSearch.Search(ids), queryParameters);
            var orderedResults = result.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);

            return GetPagedResults(orderedResults, queryParameters);
        }

        PagedResults GetPagedResults(IEnumerable<ChecklistConfigurationItem> orderedResults,
                                              CommonQueryParameters queryParameters)
        {
            if (orderedResults == null || !orderedResults.Any())
            {
                return new PagedResults(Array.Empty<string>(), 0);
            }

            var returnData = orderedResults.Skip(queryParameters.Skip.GetValueOrDefault())
                                           .Take(queryParameters.Take.GetValueOrDefault())
                                           .Select(_ => new
                                           {
                                               _.Id,
                                               ChecklistType = _commonQueryService.BuildCodeDescriptionObject(_.ChecklistTypeCode.ToString(), _.ChecklistTypeDescription),
                                               CaseType = _commonQueryService.BuildCodeDescriptionObject(_.CaseTypeCode, _.CaseTypeDescription),
                                               CaseCategory = _commonQueryService.BuildCodeDescriptionObject(_.CaseCategoryCode, _.CaseCategoryDescription),
                                               Jurisdiction = _commonQueryService.BuildCodeDescriptionObject(_.JurisdictionCode, _.JurisdictionDescription),
                                               PropertyType = _commonQueryService.BuildCodeDescriptionObject(_.PropertyTypeCode, _.PropertyTypeDescription),
                                               SubType = _commonQueryService.BuildCodeDescriptionObject(_.SubTypeCode, _.SubTypeDescription),
                                               Basis = _commonQueryService.BuildCodeDescriptionObject(_.BasisCode, _.BasisDescription),
                                               Office = _commonQueryService.BuildCodeDescriptionObject(_.OfficeCode.ToString(), _.OfficeDescription),
                                               _.IsLocalClient,
                                               _.InUse,
                                               _.CriteriaName,
                                               _.IsProtected,
                                               _.IsInherited,
                                               IsHighestParent = _.IsParent && !_.IsInherited
                                           });

            return new PagedResults(returnData, orderedResults.Count());
        }
    }
}
