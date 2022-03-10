using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.DmsIntegration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Profiles;
using System.Threading.Tasks;
using System.Web.Http;

namespace Inprotech.Web.DocumentManagement
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/document-management")]
    public class DocumentManagementViewDataController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IUserPreferenceManager _userPreferenceManager;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public DocumentManagementViewDataController(IUserPreferenceManager userPreferenceManager, ISecurityContext securityContext, ITaskSecurityProvider taskSecurityProvider)
        {
            _userPreferenceManager = userPreferenceManager;
            _securityContext = securityContext;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("view-data")]
        public async Task<dynamic> GetViewData()
        {
            string errors = null;
            if (!_taskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms))
            {
                errors = KnownDocumentManagementEvents.MissingTaskPermission;
            }
            return new
            {
                Errors = errors,
                UseImanageWorkLink = _userPreferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.UseImanageWorkLink)
            };
        }
    }
}