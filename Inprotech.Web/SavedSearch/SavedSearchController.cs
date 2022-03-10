using System.Linq;
using Inprotech.Infrastructure.ResponseEnrichment;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.SavedSearch
{
    [Authorize]
    [RoutePrefix("api/savedsearch")]
    [NoEnrichment]
    public class SavedSearchController : ApiController
    {
        readonly ISavedSearchMenu _savedSearchMenu;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public SavedSearchController(ISavedSearchMenu savedSearchMenu, ITaskSecurityProvider taskSecurityProvider)
        {
            _savedSearchMenu = savedSearchMenu;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("menu/{queryContextKey}")]
        public dynamic Menu(QueryContext queryContextKey)
        {
            CheckSecurity(queryContextKey);
            return _savedSearchMenu.Build(queryContextKey, string.Empty);
        }

        void CheckSecurity(QueryContext queryContextKey)
        {
            var allowedTasks = _taskSecurityProvider.ListAvailableTasks().ToArray();

            ApplicationTask? taskSecurity = null;

            if (queryContextKey != QueryContext.CaseSearch || 
                queryContextKey == QueryContext.CaseSearchExternal)
            {
                taskSecurity = ApplicationTask.RunSavedCaseSearch;
            }

            if (taskSecurity != null && allowedTasks.All(_ => _.TaskId != (short)taskSecurity))
            {
                throw Exceptions.Forbidden(Properties.Resources.ErrorSecurityTaskAccessCheckFailure);
            }
        }
    }
}
