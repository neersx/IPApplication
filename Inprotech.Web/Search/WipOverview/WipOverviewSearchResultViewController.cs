using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Reports;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search.WipOverview
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.RunSavedWipOverviewSearch)]
    [RequiresAccessTo(ApplicationTask.AdvancedWipOverviewSearch)]
    [RoutePrefix("api/search/wipoverview")]
    public class WipOverviewSearchResultViewController : ApiController, ISearchResultViewController
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly WipOverviewSearchController _wipOverviewSearchController;
        readonly IReportsController _reportsController;
        readonly ISearchResultSelector _searchResultSelector;
        readonly ISiteControlReader _siteControlReader;
        readonly IEntities _entities;
        public WipOverviewSearchResultViewController(IDbContext dbContext, ISecurityContext securityContext, ITaskSecurityProvider taskSecurityProvider, WipOverviewSearchController wipOverviewSearchController, IReportsController reportsController, ISearchResultSelector searchResultSelector, ISiteControlReader siteControlReader, IEntities entities)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _taskSecurityProvider = taskSecurityProvider;
            _wipOverviewSearchController = wipOverviewSearchController;
            _reportsController = reportsController;
            _searchResultSelector = searchResultSelector;
            _siteControlReader = siteControlReader;
            _entities = entities;
        }

        [Route("view")]
        public async Task<dynamic> Get(int? queryKey, QueryContext queryContext)
        {
            if (QueryContext.WipOverviewSearch != queryContext) return BadRequest();

            var queryName = string.Empty;
            if (queryKey.HasValue)
            {
                queryName = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == queryKey.Value)?.Name;
            }
            var billingWorksheetTimeout = _dbContext.Set<SettingValues>()
                                     .Where(v => (v.User == null || v.User.Id == _securityContext.User.Id) && v.SettingId == KnownSettingIds.BillingWorksheetReportPushtoBackgroundTimeout)
                                     .OrderByDescending(_ => _.User != null)
                                     .FirstOrDefault()?.IntegerValue.GetValueOrDefault();

            var entities = (await _entities.Get(_securityContext.User.NameId))
                .Select(_ => new
                {
                    EntityKey = _.Id,
                    EntityName = _.DisplayName,
                    _.IsDefault
                });

            return new
            {
                isExternal = _securityContext.User.IsExternalUser,
                QueryName = queryName,
                QueryContext = (int)queryContext,
                ReportProviderInfo = await _reportsController.GetReportProviderInfo(),
                BillingWorksheetTimeout = billingWorksheetTimeout.HasValue ? billingWorksheetTimeout.Value * 1000 : (int?)null,
                Permissions = new
                {
                    CanMaintainDebitNote = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create),
                    CanCreateBillingWorksheet = _taskSecurityProvider.HasAccessTo(ApplicationTask.BillingWorksheet)
                },
                ExportLimit = _siteControlReader.Read<int?>(SiteControls.ExportLimit),
                Entities = entities
            };
        }

        [HttpPost]
        [Route("additionalviewdata")]
        public async Task<dynamic> AdditionalViewData(AdditionalViewDataRequest request)
        {
            var filterCriteria = request.SearchRequestParams.Criteria.XmlSearchRequest;
            DateTime? filterFromDate = null;
            DateTime? filterToDate = null;
            bool? isNonRenewalWip = null;
            bool? isRenewalWip = null;
            bool? isUseRenewalDebtor = null;
            SearchResult searchResult = null;

            if (request.SearchRequestParams.QueryKey.HasValue && string.IsNullOrWhiteSpace(filterCriteria))
            {
                var filterId = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == request.SearchRequestParams.QueryKey.Value)?.FilterId;
                filterCriteria = _dbContext.Set<QueryFilter>().FirstOrDefault(_ => _.Id == filterId)?.XmlFilterCriteria;
            }

            if (!string.IsNullOrEmpty(filterCriteria))
            {
                filterFromDate = SearchFilterFinder.GetFromDate(filterCriteria, "ItemDate");
                filterToDate = SearchFilterFinder.GetToDate(filterCriteria, "ItemDate");
                isNonRenewalWip = SearchFilterFinder.GetBoolean(filterCriteria, "RenewalWip", "IsNonRenewal");
                isRenewalWip = SearchFilterFinder.GetBoolean(filterCriteria, "RenewalWip", "IsRenewal");
                isUseRenewalDebtor = SearchFilterFinder.GetBoolean(filterCriteria, "Debtor", "@IsRenewalDebtor");
            }

            if (request.HasAllSelected)
            {
                var searchParam = request.SearchRequestParams as SavedSearchRequestParams<WipOverviewSearchRequestFilter>;
                if (request.SearchRequestParams.QueryKey.HasValue)
                {
                    searchParam.QueryKey = request.SearchRequestParams.QueryKey.Value;
                    searchResult = await _wipOverviewSearchController.RunEditedSavedSearch(searchParam);
                }
                else
                {
                    searchResult = await _wipOverviewSearchController.RunSearch(searchParam);
                }

                if (request.DeSelectedIds != null && request.DeSelectedIds.Any())
                {
                    searchResult = _searchResultSelector.GetActualSelectedRecords(searchResult, searchParam.QueryContext, request.DeSelectedIds);
                }
            }

            return new
            {
                filterFromDate,
                filterToDate,
                isNonRenewalWip,
                isRenewalWip,
                isUseRenewalDebtor,
                searchResult
            };
        }
        
        public class AdditionalViewDataRequest
        {
            public ExtendedSearchRequestParam SearchRequestParams { get; set; }

            public bool HasAllSelected { get; set; }

            public int[] DeSelectedIds { get; set; }
        }

        public class ExtendedSearchRequestParam : SavedSearchRequestParams<WipOverviewSearchRequestFilter>
        {
            public new int? QueryKey { get; set; }
        }
    }
}