using System;
using System.Net;
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
    public class NameSearchMaintenanceController : ApiController
    {
        readonly QueryContext _queryContext;
        readonly ISavedSearchService _savedSearchService;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public NameSearchMaintenanceController(
            ISecurityContext securityContext,
            ISavedSearchService savedSearchService,
            ITaskSecurityProvider taskSecurityProvider)
        {
            _savedSearchService = savedSearchService;
            _taskSecurityProvider = taskSecurityProvider;

            _queryContext = securityContext.User.IsExternalUser
                ? QueryContext.NameSearchExternal
                : QueryContext.NameSearch;
        }

        [HttpPost]
        [Route("add")]
        [RequiresAccessTo(ApplicationTask.MaintainNameSearch, ApplicationTaskAccessLevel.Create)]
        [NoEnrichment]
        public dynamic Add(FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.SearchFilter == null) throw new ArgumentNullException(nameof(filteredSavedSearch.SearchFilter));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.SaveSearch(filteredSavedSearch);
        }

        [HttpGet]
        [Route("get/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainNameSearch, ApplicationTaskAccessLevel.None)]
        [NoEnrichment]
        public SavedSearch Get(int? queryKey)
        {
            if (queryKey == null) throw new ArgumentNullException(nameof(queryKey));

            return _savedSearchService.Get(queryKey.Value);
        }

        [HttpGet]
        [Route("deleteSavedSearch/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainNameSearch, ApplicationTaskAccessLevel.Delete)]
        [NoEnrichment]
        public dynamic DeleteSavedSearch(int? queryKey)
        {
            if (queryKey == null) throw new ArgumentNullException(nameof(queryKey));

            return _savedSearchService.DeleteSavedSearch(queryKey.Value);
        }

        [HttpPut]
        [Route("update/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainNameSearch, ApplicationTaskAccessLevel.Modify)]
        [NoEnrichment]
        public dynamic Update(int queryKey, FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.Update(queryKey, filteredSavedSearch);
        }

        [HttpPost]
        [Route("saveas/{fromQueryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainNameSearch, ApplicationTaskAccessLevel.Create)]
        [NoEnrichment]
        public dynamic SaveAs(int fromQueryKey, FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.SaveAsSearch(fromQueryKey, filteredSavedSearch);
        }

        [HttpPut]
        [Route("updateDetails/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainNameSearch, ApplicationTaskAccessLevel.Modify)]
        [NoEnrichment]
        public dynamic UpdateDetails(int queryKey, FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

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