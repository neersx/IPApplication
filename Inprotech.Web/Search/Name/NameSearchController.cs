using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Names.Search;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Search.Name
{
    [Authorize]
    [RoutePrefix("api/search/name")]
    public class NameSearchController : ApiController,
                                        ISearchController<NameSearchRequestFilter<NameSearchRequest>>,
                                        IExportableSearchController<NameSearchRequestFilter<NameSearchRequest>>
    {
        readonly QueryContext _allowedQueryContext;
        readonly ISearchExportService _searchExportService;
        readonly ISearchService _searchService;
        readonly INameSearchService _nameSearchService;

        public NameSearchController(ISecurityContext securityContext,
                                    ISearchService searchService,
                                    ISearchExportService searchExportService,
                                    INameSearchService nameSearchService)
        {
            _searchService = searchService;
            _searchExportService = searchExportService;
            _nameSearchService = nameSearchService;

            _allowedQueryContext = securityContext.User.IsExternalUser
                ? QueryContext.NameSearchExternal
                : QueryContext.NameSearch;
        }

        [HttpPost]
        [Route("export")]
        [RequiresAccessTo(ApplicationTask.AdvancedNameSearch)]
        [RequiresAccessTo(ApplicationTask.QuickNameSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedNameSearch)]
        [NoEnrichment]
        public async Task Export(SearchExportParams<NameSearchRequestFilter<NameSearchRequest>> searchExportParams)
        {
            if (searchExportParams == null) throw new ArgumentNullException(nameof(searchExportParams));
            if (searchExportParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            _nameSearchService.UpdateFilterForBulkOperation(searchExportParams);
            await _searchExportService.Export(searchExportParams);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.AdvancedNameSearch)]
        [RequiresAccessTo(ApplicationTask.QuickNameSearch)]
        [NoEnrichment]
        public async Task<SearchResult> RunSearch(SearchRequestParams<NameSearchRequestFilter<NameSearchRequest>> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("columns")]
        [RequiresAccessTo(ApplicationTask.AdvancedNameSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedNameSearch)]
        [RequiresAccessTo(ApplicationTask.QuickNameSearch)]
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
        [RequiresAccessTo(ApplicationTask.AdvancedNameSearch)]
        [NoEnrichment]
        public async Task<SearchResult> RunEditedSavedSearch(SavedSearchRequestParams<NameSearchRequestFilter<NameSearchRequest>> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunEditedSavedSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("filterData")]
        [RequiresAccessTo(ApplicationTask.AdvancedNameSearch)]
        [RequiresAccessTo(ApplicationTask.QuickNameSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedNameSearch)]
        [NoEnrichment]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(ColumnFilterParams<NameSearchRequestFilter<NameSearchRequest>> columnFilterParams)
        {
            if (columnFilterParams == null) throw new ArgumentNullException(nameof(columnFilterParams));
            if (columnFilterParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetFilterDataForColumn(columnFilterParams);
        }

        [HttpPost]
        [RequiresAccessTo(ApplicationTask.RunSavedNameSearch)]
        [Route("savedSearch")]
        [NoEnrichment]
        public async Task<SearchResult> RunSavedSearch(SavedSearchRequestParams<NameSearchRequestFilter<NameSearchRequest>> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSavedSearch(searchRequestParams);
        }
    }
}