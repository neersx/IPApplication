using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Search.WipOverview;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Search.WipOverview
{
    [Authorize]
    [RoutePrefix("api/search/wipoverview")]
    public class WipOverviewSearchController : ApiController,
                                               ISearchController<WipOverviewSearchRequestFilter>,
                                               IExportableSearchController<WipOverviewSearchRequestFilter>
    {
        readonly ISearchExportService _searchExportService;
        readonly ISearchService _searchService;
        readonly ICreateBillValidator _createBillValidator;
        readonly IEntities _entities;

        public WipOverviewSearchController(ISearchService searchService,
                                           ISearchExportService searchExportService,
                                           ICreateBillValidator createBillValidator,
                                           IEntities entities)
        {
            _searchService = searchService;
            _searchExportService = searchExportService;
            _createBillValidator = createBillValidator;
            _entities = entities;
        }

        [HttpPost]
        [Route("export")]
        [RequiresAccessTo(ApplicationTask.AdvancedWipOverviewSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedWipOverviewSearch)]
        [NoEnrichment]
        public async Task Export(SearchExportParams<WipOverviewSearchRequestFilter> searchExportParams)
        {
            if (searchExportParams == null) throw new ArgumentNullException(nameof(searchExportParams));
            if (searchExportParams.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            if (searchExportParams.DeselectedIds != null && searchExportParams.DeselectedIds.Any() && searchExportParams.Criteria != null)
            {
                var wipRowKeys = new SearchElement
                {
                    Value = string.Join(",", searchExportParams.DeselectedIds),
                    Operator = (short)CollectionExtensions.FilterOperator.NotIn
                };
                var requests = (searchExportParams.Criteria.SearchRequest ?? new List<WipOverviewSearchRequest>()).ToList();

                if (!requests.Any())
                {
                    requests.Add(new WipOverviewSearchRequest());
                }
                requests.First().RowKeys = wipRowKeys;
                searchExportParams.Criteria.SearchRequest = requests;
            }

            await _searchExportService.Export(searchExportParams);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.AdvancedWipOverviewSearch)]
        [NoEnrichment]
        public async Task<SearchResult> RunSearch(SearchRequestParams<WipOverviewSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("columns")]
        [RequiresAccessTo(ApplicationTask.AdvancedWipOverviewSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedWipOverviewSearch)]
        [NoEnrichment]
        public async Task<IEnumerable<SearchResult.Column>> SearchColumns(ColumnRequestParams columnRequest)
        {
            if (columnRequest == null) throw new ArgumentNullException(nameof(columnRequest));
            if (columnRequest.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetSearchColumns(
                                                         columnRequest.QueryContext,
                                                         columnRequest.QueryKey,
                                                         columnRequest.SelectedColumns,
                                                         columnRequest.PresentationType);
        }

        [HttpPost]
        [Route("editedSavedSearch")]
        [RequiresAccessTo(ApplicationTask.AdvancedWipOverviewSearch)]
        [NoEnrichment]
        public async Task<SearchResult> RunEditedSavedSearch(SavedSearchRequestParams<WipOverviewSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunEditedSavedSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("filterData")]
        [RequiresAccessTo(ApplicationTask.AdvancedWipOverviewSearch)]
        [RequiresAccessTo(ApplicationTask.RunSavedWipOverviewSearch)]
        [NoEnrichment]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(ColumnFilterParams<WipOverviewSearchRequestFilter> columnFilterParams)
        {
            if (columnFilterParams == null) throw new ArgumentNullException(nameof(columnFilterParams));
            if (columnFilterParams.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetFilterDataForColumn(columnFilterParams);
        }

        [HttpPost]
        [RequiresAccessTo(ApplicationTask.RunSavedWipOverviewSearch)]
        [Route("savedSearch")]
        [NoEnrichment]
        public async Task<SearchResult> RunSavedSearch(SavedSearchRequestParams<WipOverviewSearchRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.RunSavedSearch(searchRequestParams);
        }

        [HttpPost]
        [RequiresAccessTo(ApplicationTask.RunSavedWipOverviewSearch)]
        [Route("validateSingleBillCreation")]
        [NoEnrichment]
        public async Task<IEnumerable<CreateBillValidationError>> PrepareCreateSingleBill(IEnumerable<CreateBillRequest> billingRequest)
        {
            var createBillRequests = billingRequest as CreateBillRequest[] ?? billingRequest.ToArray();
            if (billingRequest == null || !createBillRequests.Any()) throw new ArgumentNullException(nameof(billingRequest));

            return await _createBillValidator.Validate(createBillRequests, CreateBillValidationType.SingleBill);
        }

        [HttpGet]
        [RequiresAccessTo(ApplicationTask.RunSavedWipOverviewSearch)]
        [Route("isEntityRestrictedByCurrency/{entityKey}")]
        [NoEnrichment]
        public async Task<bool> IsEntityRestrictedByCurrency(int entityKey)
        {
            return await _entities.IsRestrictedByCurrency(entityKey);
        }
    }
}