using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting.Billing.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.Billing
{
    [Authorize]
    [RoutePrefix("api/search/billing")]
    public class BillSearchController : ApiController, ISearchController<BillSearchRequestFilter>, IExportableSearchController<BillSearchRequestFilter>
    {
        readonly QueryContext _allowedQueryContext;
        readonly ISearchExportService _searchExportService;
        readonly ISearchService _searchService;
        readonly IWebPartSecurity _webPartSecurity;
        public BillSearchController(ISearchService searchService,
                                    ISearchExportService searchExportService,
                                    IWebPartSecurity webPartSecurity)
        {
            _searchService = searchService;
            _searchExportService = searchExportService;
            _webPartSecurity = webPartSecurity;
            _allowedQueryContext = QueryContext.BillingSelection;
        }

        [HttpPost]
        [Route("export")]
        [NoEnrichment]
        public async Task Export(SearchExportParams<BillSearchRequestFilter> searchExportParams)
        {
            if (!_webPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch)) throw new HttpResponseException(HttpStatusCode.Forbidden);

            if (searchExportParams == null) throw new ArgumentNullException(nameof(searchExportParams));
            if (searchExportParams.QueryContext != QueryContext.BillingSelection) throw new HttpResponseException(HttpStatusCode.BadRequest);

            if (searchExportParams.DeselectedIds != null && searchExportParams.DeselectedIds.Any() && searchExportParams.Criteria != null)
            {
                var wipRowKeys = new SearchElement
                {
                    Value = string.Join(",", searchExportParams.DeselectedIds),
                    Operator = (short)CollectionExtensions.FilterOperator.NotIn
                };
                var requests = (searchExportParams.Criteria.SearchRequest ?? new List<BillSearchRequest>()).ToList();

                if (!requests.Any())
                {
                    requests.Add(new BillSearchRequest());
                }

                requests.First().RowKeys = wipRowKeys;
                searchExportParams.Criteria.SearchRequest = requests;
            }

            await _searchExportService.Export(searchExportParams);
        }

        [HttpPost]
        [Route("")]
        [NoEnrichment]
        public async Task<SearchResult> RunSearch(SearchRequestParams<BillSearchRequestFilter> searchRequestParams)
        {
            if (!_webPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch)) throw new HttpResponseException(HttpStatusCode.Forbidden);

            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("savedSearch")]
        [NoEnrichment]
        public async Task<SearchResult> RunSavedSearch(SavedSearchRequestParams<BillSearchRequestFilter> searchRequestParams)
        {
            if (!_webPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch)) throw new HttpResponseException(HttpStatusCode.Forbidden);

            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSavedSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("editedSavedSearch")]
        [NoEnrichment]
        public async Task<SearchResult> RunEditedSavedSearch(SavedSearchRequestParams<BillSearchRequestFilter> searchRequestParams)
        {
            if (!_webPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch)) throw new HttpResponseException(HttpStatusCode.Forbidden);

            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunEditedSavedSearch(searchRequestParams);
        }
        
        [HttpPost]
        [Route("columns")]
        [NoEnrichment]
        public async Task<IEnumerable<SearchResult.Column>> SearchColumns(ColumnRequestParams columnRequest)
        {
            if (!_webPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch)) throw new HttpResponseException(HttpStatusCode.Forbidden);

            if (columnRequest == null) throw new ArgumentNullException(nameof(columnRequest));
            if (columnRequest.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetSearchColumns(
                                                         columnRequest.QueryContext,
                                                         columnRequest.QueryKey,
                                                         columnRequest.SelectedColumns,
                                                         columnRequest.PresentationType);
        }

        [HttpPost]
        [Route("filterData")]
        [NoEnrichment]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(ColumnFilterParams<BillSearchRequestFilter> columnFilterParams)
        {
            if (!_webPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch)) throw new HttpResponseException(HttpStatusCode.Forbidden);

            if (columnFilterParams == null) throw new ArgumentNullException(nameof(columnFilterParams));
            if (columnFilterParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetFilterDataForColumn(columnFilterParams);
        }
    }

    public class BillSearchActionRequest
    {
        public int EntityNo { get; set; }
        public string ItemNo { get; set; }
    }

}