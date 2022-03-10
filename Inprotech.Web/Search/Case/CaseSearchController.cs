using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search.Export;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Search.Case
{
    [Authorize]
    [RoutePrefix("api/search/case")]
    public class CaseSearchController : ApiController,
                                        ISearchController<CaseSearchRequestFilter>,
                                        IExportableSearchController<CaseSearchRequestFilter>
    {
        readonly QueryContext _allowedQueryContext;
        readonly ICaseSearchService _caseSearch;
        readonly ICpaXmlExporter _cpaXmlExporter;
        readonly ISearchExportService _searchExportService;
        readonly ISearchService _searchService;

        public CaseSearchController(ISecurityContext securityContext,
                                    ISearchService searchService,
                                    ICaseSearchService caseSearch,
                                    ISearchExportService searchExportService,
                                    ICpaXmlExporter cpaXmlExporter)
        {
            _searchService = searchService;
            _caseSearch = caseSearch;
            _searchExportService = searchExportService;
            _cpaXmlExporter = cpaXmlExporter;

            _allowedQueryContext = securityContext.User.IsExternalUser
                ? QueryContext.CaseSearchExternal
                : QueryContext.CaseSearch;
        }

        [HttpPost]
        [Route("export")]
        [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
        [RequiresAccessTo(ApplicationTask.QuickCaseSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedCaseSearch)]
        [NoEnrichment]
        public async Task Export(SearchExportParams<CaseSearchRequestFilter> searchExportParams)
        {
            if (searchExportParams == null) throw new ArgumentNullException(nameof(searchExportParams));
            if (searchExportParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);
            
            CaseSearchHelper.DeSelectedIds = searchExportParams.DeselectedIds;
            if (searchExportParams.DeselectedIds!= null && searchExportParams.DeselectedIds.Any())
            {
                var caseKeys = new SearchElement
                {
                    Value = string.Join(",", searchExportParams.DeselectedIds),
                    Operator = 1
                };

                if (searchExportParams.Criteria?.SearchRequest != null)
                {
                    foreach (var request in searchExportParams.Criteria.SearchRequest)
                    {
                        if (request.CaseKeys != null && !string.IsNullOrEmpty(request.CaseKeys.Value) )
                        {
                            var selectedCaseIds = request.CaseKeys.Value.Split(',').Select(int.Parse).ToList();

                            request.CaseKeys.Value = string.Join(",", request.CaseKeys.Operator == 0 ? selectedCaseIds.Except(searchExportParams.DeselectedIds) : selectedCaseIds.Union(searchExportParams.DeselectedIds));
                        }
                        else
                        {
                            request.CaseKeys = caseKeys;
                        }

                    }
                }
                else if (searchExportParams.Criteria != null)
                {
                    searchExportParams.Criteria.SearchRequest = new List<CaseSearchRequest>
                    {
                        new CaseSearchRequest {CaseKeys = caseKeys}
                    };
                }
            }

            await _searchExportService.Export(searchExportParams);
        }
        
        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
        [RequiresAccessTo(ApplicationTask.QuickCaseSearch)]
        [NoEnrichment]
        public async Task<SearchResult> RunSearch(SearchRequestParams<CaseSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("columns")]
        [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedCaseSearch)]
        [RequiresAccessTo(ApplicationTask.QuickCaseSearch)]
        [NoEnrichment]
        public async Task<IEnumerable<SearchResult.Column>> SearchColumns(ColumnRequestParams columnRequest)
        {
            if (columnRequest == null) throw new ArgumentNullException(nameof(columnRequest));
            if (columnRequest.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetSearchColumns(
                                                         columnRequest.QueryContext,
                                                         columnRequest.QueryKey,
                                                         columnRequest.SelectedColumns,
                                                         columnRequest.PresentationType);
        }

        [HttpPost]
        [Route("editedSavedSearch")]
        [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
        [NoEnrichment]
        public async Task<SearchResult> RunEditedSavedSearch(SavedSearchRequestParams<CaseSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            bool forceConstructXmlCriteria = searchRequestParams.Criteria?.SearchRequest != null;

            return await _searchService.RunEditedSavedSearch(searchRequestParams, forceConstructXmlCriteria);
        }

        [HttpPost]
        [RequiresAccessTo(ApplicationTask.RunSavedCaseSearch)]
        [Route("savedSearch")]
        [NoEnrichment]
        public async Task<SearchResult> RunSavedSearch(SavedSearchRequestParams<CaseSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSavedSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("filterData")]
        [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
        [RequiresAccessTo(ApplicationTask.QuickCaseSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedCaseSearch)]
        [NoEnrichment]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(ColumnFilterParams<CaseSearchRequestFilter> columnFilterParams)
        {
            if (columnFilterParams == null) throw new ArgumentNullException(nameof(columnFilterParams));
            if (columnFilterParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetFilterDataForColumn(columnFilterParams);
        }

        [HttpPost]
        [Route("dueDateSavedSearch")]
        [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
        [NoEnrichment]
        public async Task<SearchResult> DueDateSavedSearch(SavedSearchRequestParams<CaseSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);
            if (searchRequestParams.Criteria == null) return new SearchResult();

            return await _caseSearch.GetDueDateOnlyCaseSearchResult(
                                                                    searchRequestParams.QueryKey.GetValueOrDefault(),
                                                                    searchRequestParams.Criteria,
                                                                    searchRequestParams.Params ?? new CommonQueryParameters());
        }

        [HttpGet]
        [RequiresAccessTo(ApplicationTask.RunSavedCaseSearch)]
        [Route("dueDatePresentation/{queryKey}")]
        [NoEnrichment]
        public dynamic DueDatePresentation(int queryKey)
        {
            var presentationColumns = _caseSearch.DueDatePresentationColumn(queryKey);

            IEnumerable<KeyValuePair<string, string>> importanceOptions = null;
            if (presentationColumns.HasDueDatePresentationColumn || presentationColumns.HasAllDatePresentationColumn)
            {
                importanceOptions = _caseSearch.GetImportanceLevels();
            }

            return new
            {
                presentationColumns.HasDueDatePresentationColumn,
                presentationColumns.HasAllDatePresentationColumn,
                ImportanceOptions = importanceOptions
            };
        }

        [HttpPost]
        [Route("exportToCpaXml")]
        [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedCaseSearch)]
        [RequiresAccessTo(ApplicationTask.QuickCaseSearch)]
        [NoEnrichment]
        public async Task<CpaXmlResult> ExportToCpaXml(SearchExportParams<CaseSearchRequestFilter> searchExportParams)
        {
            if (searchExportParams == null) throw new ArgumentNullException(nameof(searchExportParams));
            if (searchExportParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var caseIds = await CaseIdsForBulkOperations(searchExportParams);

            string ids = string.Join(",", caseIds);
            return await _cpaXmlExporter.ScheduleCpaXmlImport(ids);
        }

        [HttpPost]
        [Route("caseIds")]
        [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedCaseSearch)]
        [RequiresAccessTo(ApplicationTask.QuickCaseSearch)]
        [NoEnrichment]
        public async Task<IEnumerable<int>> CaseIdsForBulkOperations(SearchExportParams<CaseSearchRequestFilter> searchExportParams)
        {
            if (searchExportParams == null) throw new ArgumentNullException(nameof(searchExportParams));
            if (searchExportParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            _caseSearch.UpdateFilterForBulkOperation(searchExportParams);

            return await _caseSearch.DistinctCaseIdsForBulkOperations(searchExportParams);
        }
    }
}