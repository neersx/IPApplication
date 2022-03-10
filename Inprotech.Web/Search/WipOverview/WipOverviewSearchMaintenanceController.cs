using System;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search;

namespace Inprotech.Web.Search.WipOverview
{
    [Authorize]
    [RoutePrefix("api/search/wipoverview")]
    public class WipOverviewSearchMaintenanceController : ApiController
    {
        readonly ISavedSearchService _savedSearchService;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public WipOverviewSearchMaintenanceController(
            ISavedSearchService savedSearchService,
            ITaskSecurityProvider taskSecurityProvider)
        {
            _savedSearchService = savedSearchService;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpPost]
        [Route("add")]
        [RequiresAccessTo(ApplicationTask.MaintainWipOverviewSearch, ApplicationTaskAccessLevel.Create)]
        [NoEnrichment]
        public dynamic Add(FilteredSavedSearch<WipOverviewSearchRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.SearchFilter == null) throw new ArgumentNullException(nameof(filteredSavedSearch.SearchFilter));
            if (filteredSavedSearch.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.SaveSearch(filteredSavedSearch);
        }

        [HttpGet]
        [Route("get/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainWipOverviewSearch, ApplicationTaskAccessLevel.None)]
        [NoEnrichment]
        public SavedSearch Get(int? queryKey)
        {
            if (queryKey == null) throw new ArgumentNullException(nameof(queryKey));

            return _savedSearchService.Get(queryKey.Value);
        }

        [HttpGet]
        [Route("deleteSavedSearch/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainWipOverviewSearch, ApplicationTaskAccessLevel.Delete)]
        [NoEnrichment]
        public dynamic DeleteSavedSearch(int? queryKey)
        {
            if (queryKey == null) throw new ArgumentNullException(nameof(queryKey));

            return _savedSearchService.DeleteSavedSearch(queryKey.Value);
        }

        [HttpPut]
        [Route("update/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainWipOverviewSearch, ApplicationTaskAccessLevel.Modify)]
        [NoEnrichment]
        public dynamic Update(int queryKey, FilteredSavedSearch<WipOverviewSearchRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.Update(queryKey, filteredSavedSearch);
        }

        [HttpPost]
        [Route("saveas/{fromQueryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainWipOverviewSearch, ApplicationTaskAccessLevel.Create)]
        [NoEnrichment]
        public dynamic SaveAs(int fromQueryKey, FilteredSavedSearch<WipOverviewSearchRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.SaveAsSearch(fromQueryKey, filteredSavedSearch);
        }

        [HttpPut]
        [Route("updateDetails/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainWipOverviewSearch, ApplicationTaskAccessLevel.Modify)]
        [NoEnrichment]
        public dynamic UpdateDetails(int queryKey, FilteredSavedSearch<WipOverviewSearchRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != QueryContext.WipOverviewSearch) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.Update(queryKey, filteredSavedSearch, true);
        }

        void CheckAccess(SavedSearch nameFilteredSavedSearch)
        {
            if (nameFilteredSavedSearch.IsPublic && !_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch))
            {
                throw new UnauthorizedAccessException();
            }
        }
    }
}