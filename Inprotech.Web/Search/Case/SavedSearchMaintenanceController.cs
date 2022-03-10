using System;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search.Case
{
    [Authorize]
    [RoutePrefix("api/search/case")]
    public class SavedSearchMaintenanceController : ApiController
    {
        readonly QueryContext _queryContext;
        readonly ISavedSearchService _savedSearchService;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IDbContext _dbContext;

        public SavedSearchMaintenanceController(ISecurityContext securityContext,
                                               ISavedSearchService savedSearchService,
                                               ITaskSecurityProvider taskSecurityProvider, IDbContext dbContext)
        {
            _savedSearchService = savedSearchService;
            _taskSecurityProvider = taskSecurityProvider;
            _dbContext = dbContext;

            _queryContext = securityContext.User.IsExternalUser
                ? QueryContext.CaseSearchExternal
                : QueryContext.CaseSearch;
        }

        [HttpPost]
        [Route("add")]
        [RequiresAccessTo(ApplicationTask.MaintainCaseSearch, ApplicationTaskAccessLevel.Create)]
        [NoEnrichment]
        public dynamic Add(FilteredSavedSearch<CaseSearchRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.SearchFilter == null) throw new ArgumentNullException(nameof(filteredSavedSearch.SearchFilter));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.SaveSearch(filteredSavedSearch);
        }

        [HttpGet]
        [Route("get/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainCaseSearch, ApplicationTaskAccessLevel.None)]
        [NoEnrichment]
        public SavedSearch Get(int? queryKey)
        {
            if (queryKey == null)
            {
                throw new ArgumentNullException(nameof(queryKey));
            }

            return _savedSearchService.Get(queryKey.Value);
        }

        [HttpGet]
        [Route("deleteSavedSearch/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainCaseSearch, ApplicationTaskAccessLevel.Delete)]
        [NoEnrichment]
        public dynamic DeleteSavedSearch(int? queryKey)
        {
            if (queryKey == null) throw new ArgumentNullException(nameof(queryKey));

            return _savedSearchService.DeleteSavedSearch(queryKey.Value);
        }

        [HttpPut]
        [Route("update/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainCaseSearch, ApplicationTaskAccessLevel.Modify)]
        [NoEnrichment]
        public dynamic Update(int? queryKey, FilteredSavedSearch<CaseSearchRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            ConstructFilterCriteria(filteredSavedSearch, queryKey);

            return _savedSearchService.Update(queryKey, filteredSavedSearch);
        }

        [HttpPost]
        [Route("saveas/{fromQueryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainCaseSearch, ApplicationTaskAccessLevel.Create)]
        [NoEnrichment]
        public dynamic SaveAs(int fromQueryKey, FilteredSavedSearch<CaseSearchRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);
            ConstructFilterCriteria(filteredSavedSearch, fromQueryKey);

            return _savedSearchService.SaveAsSearch(fromQueryKey, filteredSavedSearch);
        }

        [HttpPut]
        [Route("updateDetails/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainCaseSearch, ApplicationTaskAccessLevel.Modify)]
        [NoEnrichment]
        public dynamic UpdateDetails(int queryKey, FilteredSavedSearch<CaseSearchRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);
            ConstructFilterCriteria(filteredSavedSearch, queryKey);

            return _savedSearchService.Update(queryKey, filteredSavedSearch, true);
        }

        void CheckAccess(SavedSearch caseSavedSearch)
        {
            if (caseSavedSearch.IsPublic && !_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch))
            {
                throw new UnauthorizedAccessException();
            }
        }

        void ConstructFilterCriteria(FilteredSavedSearch<CaseSearchRequestFilter> caseSavedSearch, int? queryKey = null)
        {
            var query = _dbContext.Set<Query>().Single(_ => _.Id == queryKey);
            var queryFilter = _dbContext.Set<QueryFilter>().Single(_ => _.Id == query.FilterId).XmlFilterCriteria;

            if (caseSavedSearch.SearchFilter == null)
            {
                caseSavedSearch.XmlFilter = queryFilter;
            }
            else if (caseSavedSearch.SearchFilter != null && caseSavedSearch.SearchFilter.SearchRequest == null)
            {
                caseSavedSearch.XmlFilter = CaseSearchHelper.AddReplaceDueDateFilter(queryFilter, caseSavedSearch.SearchFilter.DueDateFilter);
            }
        }
    }
}