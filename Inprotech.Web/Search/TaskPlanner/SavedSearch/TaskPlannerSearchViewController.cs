using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search.TaskPlanner.SavedSearch
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerApplication)]
    [RoutePrefix("api/taskplanner/search")]
    public class TaskPlannerSearchViewController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ITaskPlannerSavedSearch _taskPlannerSavedSearch;

        public TaskPlannerSearchViewController(IDbContext dbContext, ITaskPlannerSavedSearch taskPlannerSavedSearch)
        {
            _dbContext = dbContext;
            _taskPlannerSavedSearch = taskPlannerSavedSearch;
        }

        [Route("builder/{queryKey}")]
        public dynamic GetTaskPlannerSavedSearchData(int queryKey)
        {
            var query = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == queryKey);
            if (query?.Filter == null) return null;
            var filter = query.Filter;

            var data = _taskPlannerSavedSearch.GetTaskPlannerSavedSearchData(filter.XmlFilterCriteria);

            return new
            {
                QueryName = query.Name,
                IsPublic = query.IdentityId == null,
                FormData = data
            };
        }
    }
}
