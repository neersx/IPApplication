using System;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Integration.Notifications
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ViewCaseDataComparison)]
    [ViewInitialiser]
    public class DuplicatesViewController : ApiController
    {
        readonly ICaseNotificationsForDuplicates _caseNotificationsForDuplicates;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public DuplicatesViewController(ITaskSecurityProvider taskSecurityProvider, ICaseNotificationsForDuplicates caseNotificationsForDuplicates)
        {
            _taskSecurityProvider = taskSecurityProvider;
            _caseNotificationsForDuplicates = caseNotificationsForDuplicates;
        }

        [HttpGet]
        [Route("api/casecomparison/duplicatesview/{dataSource?}/{forId?}")]
        public async Task<dynamic> Get(string dataSource, int? forId)
        {
            if (!Enum.TryParse(dataSource, out DataSourceType dataSourceType))
            {
                throw new ArgumentException(nameof(dataSource));
            }
            if (!forId.HasValue) throw new ArgumentException(nameof(forId));

            return new
            {
                CanUpdateCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.SaveImportedCaseData),
                Duplicates = await _caseNotificationsForDuplicates.FetchDuplicatesFor(dataSourceType, forId.Value)
            };
        }
    }
}