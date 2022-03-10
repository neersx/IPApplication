using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using Inprotech.Web.Properties;
using Inprotech.Web.Search.TaskPlanner;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.TaskPlanner;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/taskPlannerSavedSearch")]
    public class TaskPlannerSavedSearchPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _queryParameters;
        readonly ISecurityContext _securityContext;
        readonly ITaskPlannerTabResolver _taskPlannerTabResolver;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public TaskPlannerSavedSearchPicklistController(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, ITaskSecurityProvider taskSecurityProvider, ITaskPlannerTabResolver taskPlannerTabResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _taskSecurityProvider = taskSecurityProvider;
            _taskPlannerTabResolver = taskPlannerTabResolver;
            _queryParameters = new CommonQueryParameters { SortBy = "searchName" };
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(SavedSearchPicklistItem), ApplicationTask.MaintainTaskPlannerSearch)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", bool retrievePublicOnly = false)
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            var results = GetData(search);
            if (retrievePublicOnly)
            {
                results = results.Where(x => x.IsPublic);
            }

            return Helpers.GetPagedResults(results,
                                           extendedQueryParams,
                                           x => x.Key.ToString(), x => x.Description, search);
        }

        IEnumerable<SavedSearchPicklistItem> GetData(string query)
        {
            var culture = _preferredCultureResolver.Resolve();
            var identityId = _securityContext.User.Id;
            var searchText = query ?? string.Empty;
            var interimResult = from p in _dbContext.Set<Query>()
                                where p.ContextId == (int)QueryContext.TaskPlanner
                                      && (!p.IdentityId.HasValue || p.IdentityId.Value == identityId)
                                      && (p.Name.Contains(searchText) || p.Description.Contains(searchText))
                                select new SavedSearchPicklistItem
                                {
                                    Key = p.Id,
                                    Description = DbFuncs.GetTranslation(p.Description, null, null, culture),
                                    SearchName = DbFuncs.GetTranslation(p.Name, null, null, culture),
                                    PresentationId = p.PresentationId,
                                    IsPublic = !p.IdentityId.HasValue
                                };

            return interimResult;
        }

        [HttpPut]
        [Route("{id}")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> Update(short id, SavedSearchPicklistItem updateDetails)
        {
            if (updateDetails == null) throw new ArgumentNullException(nameof(updateDetails));
            CheckAccess(updateDetails);
            var validationErrors = Validate(updateDetails, Operation.Update).ToArray();
            if (validationErrors.Any()) return validationErrors.AsErrorResponse();
            var update = (from p in _dbContext.Set<Query>()
                          where p.ContextId == (int)QueryContext.TaskPlanner
                                && p.Id == id
                          select p).FirstOrDefault();

            if (update == null) throw new ArgumentNullException(nameof(update));
            update.IdentityId = updateDetails.IsPublic ? null : _securityContext.User.Id;
            update.Name = updateDetails.SearchName;
            update.Description = updateDetails.Description ?? string.Empty;
            await _dbContext.SaveChangesAsync();
            await _taskPlannerTabResolver.Clear();

            return new
            {
                Result = "success",
                updateDetails.Key
            };
        }

        [HttpDelete]
        [Route("{id}")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Delete)]
        public async Task<dynamic> Delete(int id)
        {
            var savedQuery = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == id);
            if (savedQuery == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var queryInUseMessage = CheckIfQueryIsInUse(id);
            if (queryInUseMessage != null)
            {
                return queryInUseMessage;
            }

            var deleteReq = new SavedSearchPicklistItem
            {
                IsPublic = savedQuery.IdentityId == null
            };

            CheckAccess(deleteReq);
            if (savedQuery.PresentationId.HasValue)
            {
                var columnsToRemove = _dbContext.Set<QueryContent>().Where(_ => _.PresentationId == savedQuery.PresentationId);
                _dbContext.RemoveRange(columnsToRemove);
                await _dbContext.DeleteAsync(_dbContext.Set<QueryPresentation>().Where(_ => _.Id == savedQuery.PresentationId));
            }

            await _dbContext.DeleteAsync(_dbContext.Set<Query>().Where(_ => _.Id == id));
            await _dbContext.DeleteAsync(_dbContext.Set<QueryFilter>().Where(_ => _.Id == savedQuery.FilterId));
            await _dbContext.SaveChangesAsync();
            await _taskPlannerTabResolver.Clear();

            return new
            {
                Result = "success"
            };
        }

        IEnumerable<ValidationError> Validate(SavedSearchPicklistItem request, Operation operation)
        {
            var all = _dbContext.Set<Query>().Where(_ => _.ContextId == (int)QueryContext.TaskPlanner && (_.IdentityId == null && request.IsPublic || _.IdentityId == _securityContext.User.Id && !request.IsPublic)).ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != request.Key))
            {
                throw new ArgumentException("Unable to retrieve file part name for update.");
            }

            foreach (var validationError in CommonValidations.Validate(request))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != request.Key).ToArray() : all;

            if (others.Any(_ => _.Name.IgnoreCaseEquals(request.SearchName)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }

        void CheckAccess(SavedSearchPicklistItem updateDetails)
        {
            if (updateDetails.IsPublic && !_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch))
            {
                throw Exceptions.Forbidden(Resources.ErrorSecurityTaskAccessCheckFailure);
            }
        }

        dynamic CheckIfQueryIsInUse(int queryId)
        {
            var users = _dbContext.Set<TaskPlannerTab>().Where(_ => _.QueryId == queryId).Select(_ => _.IdentityId).Distinct();

            if (users.Any(_ => _ == _securityContext.User.Id))
            {
                return ProtectedRecordErrors.CannotDeleteAsInUse.AsHandled();
            }

            var isInUse = _dbContext.Set<TaskPlannerTabsByProfile>().Any(_ => _.QueryId == queryId);
            return isInUse || users.Any() ? ProtectedRecordErrors.CannotDeleteAsRestrictedByAdmin.AsHandled() : null;
        }

        public class SavedSearchPicklistItem
        {
            [PicklistKey]
            public int Key { get; set; }

            [PicklistDescription]
            public string Description { get; set; }

            public string SearchName { get; set; }
            public int? PresentationId { get; set; }
            public bool IsPublic { get; set; }
        }

        public class ProtectedRecordErrors
        {
            public const string CannotDeleteAsInUse = "taskPlanner.savedSearchIsInUse";
            public const string CannotDeleteAsRestrictedByAdmin = "taskPlanner.savedSearchRestrictedByAdmin";
        }
    }
}