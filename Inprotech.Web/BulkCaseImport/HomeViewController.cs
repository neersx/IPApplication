using System;
using System.Net.Http;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.BulkCaseImport
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.BulkCaseImport)]
    [RoutePrefix("api/bulkcaseimport")]
    [ViewInitialiser]
    public class HomeViewController : ApiController
    {
        readonly ICaseImportTemplates _caseImportTemplates;
        
        public HomeViewController(ICaseImportTemplates caseImportTemplates)
        {
            if (caseImportTemplates == null) throw new ArgumentNullException(nameof(caseImportTemplates));
            _caseImportTemplates = caseImportTemplates;
        }

        [HttpGet]
        [Route("homeview")]
        public dynamic Get(HttpRequestMessage request)
        {
            return _caseImportTemplates.ListAvailable();
        }
    }
}