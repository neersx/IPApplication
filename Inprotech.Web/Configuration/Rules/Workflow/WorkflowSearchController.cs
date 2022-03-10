using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Office = InprotechKaizen.Model.Cases.Office;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
    [RoutePrefix("api/configuration/rules/workflows")]
    public class WorkflowSearchController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IWorkflowSearch _workflowSearch;
        readonly ICommonQueryService _commonQueryService;
        readonly IWorkflowPermissionHelper _permissionHelper;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        static readonly CommonQueryParameters DefaulQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = string.Empty // Overwrite sortBy which is default to 'id'
            });

        public WorkflowSearchController(IDbContext dbContext,
            IWorkflowSearch workflowSearch,
            ICommonQueryService commonQueryService,
            IWorkflowPermissionHelper permissionHelper,
            ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _workflowSearch = workflowSearch;
            _commonQueryService = commonQueryService;
            _permissionHelper = permissionHelper;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("view")]
        public dynamic GetViewData()
        {
            return new
            {
                HasOffices = _dbContext.Set<Office>().Any(),
                MaintainWorkflowRulesProtected = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected),
                CanCreateNegativeWorkflowRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.CreateNegativeWorkflowRules)
            };
        }

        [HttpGet]
        [Route("typeaheadSearch")]
        public PagedResults TypeaheadSearch(string search, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            var results = _dbContext.Set<Criteria>().WhereWorkflowCriteria();

            results = results.Where(_ => search == null || _.Id.ToString().Contains(search) || _.Description.Contains(search));
            var r = results.Select(_ => new CriteriaResult
            {
                Id = _.Id,
                Description = _.Description,
            });

            return Helpers.GetPagedResults(r,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Id.ToString(),
                                           x => x.Description,
                                           search);
        }

        [HttpGet]
        [Route("searchByIds")]
        public dynamic SearchByIds([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] int[] ids,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            var result = _workflowSearch.Search(ids);

            queryParameters = PrepareCommonQueryParams(queryParameters);
            queryParameters.SortBy = string.IsNullOrEmpty(queryParameters.SortBy) ? "id" : queryParameters.SortBy;

            result = _commonQueryService.Filter(result, queryParameters);
            var orderedResults = SortWorkflowList(result, queryParameters);

            if (queryParameters.GetAllIds)
                return orderedResults.Select(_ => _.Id);

            return GetPagedResults(orderedResults, queryParameters);
        }

        [HttpGet]
        [Route("search")]
        public dynamic Search(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] SearchCriteria filter,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            queryParameters = queryParameters ?? new CommonQueryParameters();

            var orderedResults = DoSearch(filter, ref queryParameters);

            if (queryParameters.GetAllIds)
                return orderedResults.Select(_ => _.Id);

            return GetPagedResults(orderedResults, queryParameters);
        }

        IEnumerable<WorkflowSearchListItem> DoSearch(SearchCriteria filter,
                                                            ref CommonQueryParameters queryParameters)
        {
            queryParameters = PrepareCommonQueryParams(queryParameters);

            if (filter.MatchType == CriteriaMatchOptions.BestCriteriaOnly)
            {
                queryParameters.Take = 1;
                queryParameters.Skip = 0;
                queryParameters.SortBy = null;
                queryParameters.Filters = queryParameters.Filters;
            }

            var result = _workflowSearch.Search(filter);

            result = _commonQueryService.Filter(result, queryParameters);
            var orderedResults = filter.MatchType == CriteriaMatchOptions.BestCriteriaOnly ?
                result.Skip(queryParameters.Skip.Value).Take(queryParameters.Take.Value) :
                SortWorkflowList(result, queryParameters);

            return orderedResults;
        }

        [HttpGet]
        [Route("filterDataByIds/{field}")]
        public IEnumerable<CodeDescription> GetFilterDataForColumnByIds(string field,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] int[] ids,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "columnFilters")] IEnumerable<CommonQueryParameters.FilterValue> columnFilters)
        {
            var queryParams = PrepareCommonQueryParams(new CommonQueryParameters { Filters = columnFilters });
            var result = _workflowSearch.Search(ids);

            result = _commonQueryService.Filter(result, queryParams);

            return GetFilterData(result, field);
        }

        [HttpGet]
        [Route("filterData/{field}")]
        public IEnumerable<CodeDescription> GetFilterDataForColumn(string field,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] SearchCriteria searchFilter,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "columnFilters")] IEnumerable<CommonQueryParameters.FilterValue> columnFilters)
        {
            var queryParams = PrepareCommonQueryParams(new CommonQueryParameters { Filters = columnFilters });
            var result = DoSearch(searchFilter, ref queryParams);

            return GetFilterData(result, field);
        }

        internal PagedResults GetPagedResults(IEnumerable<WorkflowSearchListItem> orderedResults,
            CommonQueryParameters queryParameters)
        {
            if (orderedResults == null || !orderedResults.Any())
                return new PagedResults(null, 0);

            var canEditProtected = _permissionHelper.CanEditProtected();

            var returnData = orderedResults.Skip(queryParameters.Skip.GetValueOrDefault())
                .Take(queryParameters.Take.GetValueOrDefault())
                .Select(_ => new
                {
                    _.Id,
                    CaseType = _commonQueryService.BuildCodeDescriptionObject(_.CaseTypeCode, _.CaseTypeDescription),
                    CaseCategory =
                        _commonQueryService.BuildCodeDescriptionObject(_.CaseCategoryCode, _.CaseCategoryDescription),
                    Jurisdiction =
                        _commonQueryService.BuildCodeDescriptionObject(_.JurisdictionCode, _.JurisdictionDescription),
                    PropertyType =
                        _commonQueryService.BuildCodeDescriptionObject(_.PropertyTypeCode, _.PropertyTypeDescription),
                    Action = _commonQueryService.BuildCodeDescriptionObject(_.ActionCode, _.ActionDescription),
                    SubType = _commonQueryService.BuildCodeDescriptionObject(_.SubTypeCode, _.SubTypeDescription),
                    Basis = _commonQueryService.BuildCodeDescriptionObject(_.BasisCode, _.BasisDescription),
                    Office =
                        _commonQueryService.BuildCodeDescriptionObject(_.OfficeCode.ToString(), _.OfficeDescription),
                    _.DateOfLaw,
                    _.IsLocalClient,
                    _.ExaminationTypeDescription,
                    _.RenewalTypeDescription,
                    _.InUse,
                    _.CriteriaName,
                    _.IsProtected,
                    _.IsInherited,
                    IsHighestParent = _.IsParent && !_.IsInherited,
                    CanEdit = !_.IsProtected || canEditProtected
                });

            return new PagedResults(returnData, orderedResults.Count());
        }

        internal static IEnumerable<WorkflowSearchListItem> SortWorkflowList(IEnumerable<WorkflowSearchListItem> results,
            CommonQueryParameters queryParameters)
        {
            var orderedResults = results.OrderByProperty(MapFieldName(queryParameters.SortBy, true), queryParameters.SortDir)
                                        .ThenByDescending(x => x.BestFit);

            return orderedResults;
        }

        internal static CommonQueryParameters PrepareCommonQueryParams(CommonQueryParameters queryParameters)
        {
            queryParameters = DefaulQueryParameters.Extend(queryParameters);
            queryParameters.SortBy = MapFieldName(queryParameters.SortBy, true);
            foreach (var filter in queryParameters.Filters)
            {
                filter.Field = MapFieldName(filter.Field, false);
            }

            return queryParameters;
        }

        static string MapFieldName(string name, bool useDescription)
        {
            switch (name)
            {
                case "caseType":
                case "caseCategory":
                case "jurisdiction":
                case "propertyType":
                case "action":
                case "subType":
                case "basis":
                case "office":
                    return string.Format("{0}{1}", name, useDescription ? "Description" : "Code");
                default:
                    return name;
            }
        }

        IEnumerable<CodeDescription> GetFilterData(IEnumerable<WorkflowSearchListItem> source, string field)
        {
            switch (field.ToLower())
            {
                case "jurisdiction":
                    return source
                        .OrderBy(_ => _.JurisdictionDescription)
                        .Select(
                            _ =>
                                _commonQueryService.BuildCodeDescriptionObject(_.JurisdictionCode, _.JurisdictionDescription))
                        .Distinct();
                case "action":
                    return source
                        .OrderBy(_ => _.ActionDescription)
                        .Select(_ => _commonQueryService.BuildCodeDescriptionObject(_.ActionCode, _.ActionDescription))
                        .Distinct();
            }

            return null;
        }
    }

    class CriteriaResult
    {
        public int Id { get; set; }
        public string Description { get; set; }
    }
}