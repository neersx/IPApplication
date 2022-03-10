using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.PriorArt.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.PriorArt
{
    [Authorize]
    [RoutePrefix("api/search/priorart")]
    public class PriorArtSearchController : ApiController,
                                            ISearchController<PriorArtSearchRequestFilter>,
                                            IExportableSearchController<PriorArtSearchRequestFilter>
    {
        readonly ISearchExportService _searchExportService;
        readonly ISearchService _searchService;

        public PriorArtSearchController(ISearchService searchService,
                                        ISearchExportService searchExportService)
        {
            _searchService = searchService;
            _searchExportService = searchExportService;
        }

        [HttpPost]
        [Route("export")]
        [RequiresAccessTo(ApplicationTask.AdvancedPriorArtSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedPriorArtSearch)]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [NoEnrichment]
        public async Task Export(SearchExportParams<PriorArtSearchRequestFilter> searchExportParams)
        {
            if (searchExportParams == null) throw new ArgumentNullException(nameof(searchExportParams));
            if (searchExportParams.QueryContext != QueryContext.PriorArtSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            if (searchExportParams.DeselectedIds != null && searchExportParams.Criteria != null)
            {
                var priorArtKeys = new SearchElement
                {
                    Value = string.Join(",", searchExportParams.DeselectedIds),
                    Operator = 1
                };

                if (searchExportParams.Criteria.SearchRequest != null)
                {
                    searchExportParams.Criteria.SearchRequest.First().PriorArtKeys = priorArtKeys;
                }
                else
                {
                    searchExportParams.Criteria.SearchRequest = new List<PriorArtSearchRequest>
                    {
                        new PriorArtSearchRequest {PriorArtKeys = priorArtKeys}
                    };
                }
            }

            await _searchExportService.Export(searchExportParams);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.AdvancedPriorArtSearch)]
        [NoEnrichment]
        public async Task<SearchResult> RunSearch(SearchRequestParams<PriorArtSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != QueryContext.PriorArtSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("columns")]
        [RequiresAccessTo(ApplicationTask.AdvancedPriorArtSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedPriorArtSearch)]
        [NoEnrichment]
        public async Task<IEnumerable<SearchResult.Column>> SearchColumns(ColumnRequestParams columnRequest)
        {
            if (columnRequest == null) throw new ArgumentNullException(nameof(columnRequest));
            if (columnRequest.QueryContext != QueryContext.PriorArtSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetSearchColumns(
                                                         columnRequest.QueryContext,
                                                         columnRequest.QueryKey,
                                                         columnRequest.SelectedColumns,
                                                         columnRequest.PresentationType);
        }

        [HttpPost]
        [Route("editedSavedSearch")]
        [RequiresAccessTo(ApplicationTask.AdvancedPriorArtSearch)]
        [NoEnrichment]
        public async Task<SearchResult> RunEditedSavedSearch(SavedSearchRequestParams<PriorArtSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != QueryContext.PriorArtSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunEditedSavedSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("filterData")]
        [RequiresAccessTo(ApplicationTask.AdvancedPriorArtSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedPriorArtSearch)]
        [NoEnrichment]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(ColumnFilterParams<PriorArtSearchRequestFilter> columnFilterParams)
        {
            if (columnFilterParams == null) throw new ArgumentNullException(nameof(columnFilterParams));
            if (columnFilterParams.QueryContext != QueryContext.PriorArtSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetFilterDataForColumn(columnFilterParams);
        }

        [HttpPost]
        [RequiresAccessTo(ApplicationTask.RunSavedPriorArtSearch)]
        [Route("savedSearch")]
        [NoEnrichment]
        public async Task<SearchResult> RunSavedSearch(SavedSearchRequestParams<PriorArtSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != QueryContext.PriorArtSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSavedSearch(searchRequestParams);
        }
    }
}