using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Office = InprotechKaizen.Model.Cases.Office;
using SearchCriteria = InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner.SearchCriteria;

namespace Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Delete)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Delete)]
    [RoutePrefix("api/configuration/rules/screen-designer/case")]
    public class CaseScreenDesignerSearchController : ApiController
    {
        static readonly CommonQueryParameters DefaulQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = string.Empty // Overwrite sortBy which is default to 'id'
            });

        readonly ICommonQueryService _commonQueryService;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IIndex<string, ICharacteristicsService> _characteristicsService;
        readonly ICaseScreenDesignerPermissionHelper _screenDesignerPermissionHelper;
        readonly IValidatedProgramCharacteristic _validatedProgramCharacteristic;
        readonly ICaseScreenDesignerSearch _screenDesignerSearch;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CaseScreenDesignerSearchController(ITaskSecurityProvider taskSecurityProvider, 
                                                  IDbContext dbContext,
                                                  ICaseScreenDesignerSearch screenDesignerSearch,
                                                  ICommonQueryService commonQueryService, 
                                                  IPreferredCultureResolver preferredCultureResolver,
                                                  IIndex<string, ICharacteristicsService> characteristicsService, 
                                                  ICaseScreenDesignerPermissionHelper screenDesignerPermissionHelper,
                                                  IValidatedProgramCharacteristic validatedProgramCharacteristic)
        {
            _taskSecurityProvider = taskSecurityProvider;
            _dbContext = dbContext;
            _screenDesignerSearch = screenDesignerSearch;
            _commonQueryService = commonQueryService;
            _preferredCultureResolver = preferredCultureResolver;
            _characteristicsService = characteristicsService;
            _screenDesignerPermissionHelper = screenDesignerPermissionHelper;
            _validatedProgramCharacteristic = validatedProgramCharacteristic;
        }

        [Route("viewData")]
        public ViewData GetViewData()
        {
            return new ViewData
            {
                CanMaintainProtectedRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules),
                CanMaintainRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules),
                HasOffices = _dbContext.Set<Office>().Any()
            };
        }
        
        [HttpPost]
        [Route("filterData")]
        [NoEnrichment]
        public IEnumerable<CodeDescription> GetFilterDataForColumn(ColumnFilterParams<SearchCriteria> columnFilterParams)
        {
            if (columnFilterParams == null)
                throw new ArgumentNullException(nameof(columnFilterParams));
            if (columnFilterParams.Criteria == null) return new List<CodeDescription>();

            var result = _screenDesignerSearch.Search(columnFilterParams.Criteria);
            var filterData = _screenDesignerSearch.GetFilterDataForColumnResult(result, columnFilterParams.Column);

            return filterData;
        }

        [HttpPost]
        [Route("filterDataByIds")]
        public IEnumerable<CodeDescription> GetFilterDataForColumnByIds(ColumnFilterParams<int[]> columnFilterParams)
        {
            if (columnFilterParams == null)
                throw new ArgumentNullException(nameof(columnFilterParams));
            if (columnFilterParams.Criteria == null) return new List<CodeDescription>();

            var result = _screenDesignerSearch.Search(columnFilterParams.Criteria);
            return _screenDesignerSearch.GetFilterDataForColumnResult(result, columnFilterParams.Column);
        }

        [HttpGet]
        [Route("search")]
        public dynamic Search(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")]
            SearchCriteria filter,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters queryParameters)
        {
            queryParameters = queryParameters ?? new CommonQueryParameters();

            var orderedResults = DoSearch(filter, ref queryParameters);

            if (queryParameters.GetAllIds)
            {
                return orderedResults.Select(_ => _.Id);
            }

            return GetPagedResults(orderedResults, queryParameters);
        }

        [HttpGet]
        [Route("searchByIds")]
        public dynamic SearchByIds([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] int[] ids,
                                   [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            var result = _screenDesignerSearch.Search(ids);

            queryParameters = PrepareCommonQueryParams(queryParameters);
            queryParameters.SortBy = string.IsNullOrEmpty(queryParameters.SortBy) ? "id" : queryParameters.SortBy;

            result = _commonQueryService.Filter(result, queryParameters);

            var orderedResults = result.OrderByProperty(MapFieldName(queryParameters.SortBy, true), queryParameters.SortDir)
                        .ThenByDescending(x => x.BestFit);

            if (queryParameters.GetAllIds)
                return orderedResults.Select(_ => _.Id);

            return GetPagedResults(orderedResults, queryParameters);
        }

        IEnumerable<CaseScreenDesignerListItem> DoSearch(SearchCriteria filter,
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

            var result = _commonQueryService.Filter(_screenDesignerSearch.Search(filter), queryParameters);

            var orderedResults = filter.MatchType == CriteriaMatchOptions.BestCriteriaOnly
                ? result
                : result.OrderByProperty(MapFieldName(queryParameters.SortBy, true), queryParameters.SortDir)
                        .ThenByDescending(x => x.BestFit);

            return orderedResults;
        }

        public ValidatedCharacteristic GetOffice(InprotechKaizen.Model.Cases.Office office)
        {
            return office == null
                ? new ValidatedCharacteristic()
                : new ValidatedCharacteristic(office.Id.ToString(), office.Name);
        }

        public ValidatedCharacteristic GetJurisdiction(Country jurisdiction)
        {
            return jurisdiction == null
                ? new ValidatedCharacteristic()
                : new ValidatedCharacteristic(jurisdiction.Id, jurisdiction.Name);
        }
        static CommonQueryParameters PrepareCommonQueryParams(CommonQueryParameters queryParameters)
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
                case "subType":
                case "basis":
                case "office":
                case "profile":
                    return $"{name}{(useDescription ? "Description" : "Code")}";
                case "program":
                    return $"{name}{(useDescription ? "Name" : "Id")}";
                default:
                    return name;
            }
        }

        [HttpGet]
        [Route("{criteriaId:int}/characteristics")]
        public dynamic GetWorkflowCharacteristics(int criteriaId)
        {
            var criteria = _dbContext.Set<Criteria>()
                .Include(_ => _.Office)
                .Include(_ => _.PropertyType)
                .Include(_ => _.Country)
                .Include(_ => _.SubType)
                .Include(_ => _.Basis)
                .WherePurposeCode(CriteriaPurposeCodes.WindowControl)
                .Single(_ => _.Id == criteriaId);

            var c = new WorkflowCharacteristics
            {
                Office = criteria.Office == null ? (int?)null : criteria.Office.Id,
                Jurisdiction = criteria.Country == null ? null : criteria.Country.Id,
                CaseType = criteria.CaseTypeId,
                PropertyType = criteria.PropertyType == null ? null : criteria.PropertyType.Code,
                CaseCategory = criteria.CaseCategoryId,
                SubType = criteria.SubType == null ? null : criteria.SubType.Code,
                Basis = criteria.Basis == null ? null : criteria.Basis.Code,
                Profile = criteria.Profile,
            };

            var vc = _characteristicsService[CriteriaPurposeCodes.WindowControl].GetValidCharacteristics(c);

            bool isEditProtectionBlockedByParent;
            bool isEditProtectionBlockedByDescendants;
            _screenDesignerPermissionHelper.GetEditProtectionLevelFlags(criteria, out isEditProtectionBlockedByParent, out isEditProtectionBlockedByDescendants);

            bool editBlockedByDescendants;
            var canEdit = _screenDesignerPermissionHelper.CanEdit(criteria, out editBlockedByDescendants);
            if (!canEdit)
            {
                var culture = _preferredCultureResolver.Resolve();
                var translation = _dbContext.Set<Criteria>()
               .Select(_ => new
               {
                   _.Id,
                   DescriptionT = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
               }).Single(_ => _.Id == criteriaId);
                criteria.Description = translation.DescriptionT;
            }

            var tableCodePl = PicklistModelHelper.GetPicklistOrNull(criteria.TableCodeId, criteria.TableCode?.Name);

            return new
            {
                criteria.Id,
                CriteriaName = criteria.Description?.Trim(),
                criteria.InUse,
                criteria.IsProtected,
                Office = GetOffice(criteria.Office),
                Jurisdiction = GetJurisdiction(criteria.Country),
                vc.CaseType,
                vc.PropertyType,
                vc.CaseCategory,
                vc.SubType,
                vc.Basis,
                Program = _validatedProgramCharacteristic.GetProgram(criteria.ProgramId),
                vc.Profile,
                ExaminationType = criteria.TableCode?.TableTypeId == (short)TableTypes.ExaminationType ? tableCodePl : null,
                RenewalType = criteria.TableCode?.TableTypeId == (short)TableTypes.RenewalType ? tableCodePl : null,
                IsEditProtectionBlockedByParent = isEditProtectionBlockedByParent,
                IsEditProtectionBlockedByDescendants = isEditProtectionBlockedByDescendants
            };
        }
        PagedResults GetPagedResults(IEnumerable<CaseScreenDesignerListItem> orderedResults,
                                              CommonQueryParameters queryParameters)
        {
            if (orderedResults == null || !orderedResults.Any())
            {
                return new PagedResults(new string[0], 0);
            }

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
                                               SubType = _commonQueryService.BuildCodeDescriptionObject(_.SubTypeCode, _.SubTypeDescription),
                                               Basis = _commonQueryService.BuildCodeDescriptionObject(_.BasisCode, _.BasisDescription),
                                               Office =
                                                   _commonQueryService.BuildCodeDescriptionObject(_.OfficeCode.ToString(), _.OfficeDescription),
                                               _.IsLocalClient,
                                               _.ExaminationTypeDescription,
                                               _.RenewalTypeDescription,
                                               _.InUse,
                                               Program = _commonQueryService.BuildCodeDescriptionObject(_.ProgramId, _.ProgramName),
                                               Profile = _commonQueryService.BuildCodeDescriptionObject(_.ProfileCode, _.ProfileDescription),
                                               _.CriteriaName,
                                               _.IsProtected,
                                               _.IsInherited,
                                               IsHighestParent = _.IsParent && !_.IsInherited
                                           });

            return new PagedResults(returnData, orderedResults.Count());
        }

        public class ViewData
        {
            public bool CanMaintainProtectedRules { get; set; }
            public bool CanMaintainRules { get; set; }
            public bool HasOffices { get; set; }
        }
    }
}