using System;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Integration.Notifications
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ViewCaseDataComparison)]
    [ViewInitialiser]
    public class InboxViewController : ApiController
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public InboxViewController(ITaskSecurityProvider taskSecurityProvider)
        {
            if (taskSecurityProvider == null) throw new ArgumentNullException(nameof(taskSecurityProvider));
            _taskSecurityProvider = taskSecurityProvider;
        }

        [Route("api/casecomparison/inboxview")]
        public dynamic Get()
        {
            return new
                   {
                       CanUpdateCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.SaveImportedCaseData)
                   };
        }
    }
}