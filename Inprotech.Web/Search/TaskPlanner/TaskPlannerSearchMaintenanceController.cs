using System;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.Reminders.Search;

namespace Inprotech.Web.Search.TaskPlanner
{
    [Authorize]
    [RoutePrefix("api/taskplanner")]
    public class TaskPlannerSearchMaintenanceController : ApiController
    {
        readonly QueryContext _queryContext;
        readonly ISavedSearchService _savedSearchService;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public TaskPlannerSearchMaintenanceController(ISavedSearchService savedSearchService,
                                                      ITaskSecurityProvider taskSecurityProvider)
        {
            _savedSearchService = savedSearchService;
            _taskSecurityProvider = taskSecurityProvider;
            _queryContext = QueryContext.TaskPlanner;
        }

        [HttpPost]
        [Route("add")]
        [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Create)]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        public dynamic Add(FilteredSavedSearch<TaskPlannerRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch?.SearchFilter == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.SaveSearch(filteredSavedSearch);
        }

        [HttpPut]
        [Route("update/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Modify)]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        public dynamic Update(int? queryKey, FilteredSavedSearch<TaskPlannerRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);
            CheckAccess(filteredSavedSearch);

            return _savedSearchService.Update(queryKey, filteredSavedSearch);
        }

        [HttpPut]
        [Route("updateDetails/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Modify)]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        public dynamic UpdateDetails(int queryKey, FilteredSavedSearch<TaskPlannerRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.Update(queryKey, filteredSavedSearch, true);
        }

        [HttpGet]
        [Route("get/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerApplication)]
        [NoEnrichment]
        public Web.Search.SavedSearch Get(int? queryKey)
        {
            if (queryKey == null) throw new ArgumentNullException(nameof(queryKey));

            return _savedSearchService.Get(queryKey.Value);
        }

        [HttpPost]
        [Route("saveas/{fromQueryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Create)]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        public dynamic SaveAs(int fromQueryKey, FilteredSavedSearch<TaskPlannerRequestFilter> filteredSavedSearch)
        {
            if (filteredSavedSearch == null) throw new ArgumentNullException(nameof(filteredSavedSearch));
            if (filteredSavedSearch.QueryContext != _queryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            CheckAccess(filteredSavedSearch);

            return _savedSearchService.SaveAsSearch(fromQueryKey, filteredSavedSearch);
        }

        [HttpGet]
        [Route("deleteSavedSearch/{queryKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        public dynamic DeleteSavedSearch(int? queryKey)
        {
            if (queryKey == null) throw new ArgumentNullException(nameof(queryKey));

            return _savedSearchService.DeleteSavedSearch(queryKey.Value);
        }

        void CheckAccess(Web.Search.SavedSearch taskPlannerSavedSearch)
        {
            if (taskPlannerSavedSearch.IsPublic && !_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch))
            {
               throw Exceptions.Forbidden(Properties.Resources.ErrorSecurityTaskAccessCheckFailure);
            }
        }
    }
}