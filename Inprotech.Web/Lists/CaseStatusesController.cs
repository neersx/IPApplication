using System;
using System.Web.Http;
using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Lists
{
    [Authorize]
    public class CaseStatusesController : ApiController
    {
        readonly ICaseStatuses _caseStatuses;

        public CaseStatusesController(ICaseStatuses caseStatuses)
        {
            if(caseStatuses == null) throw new ArgumentNullException("caseStatuses");
            _caseStatuses = caseStatuses;
        }

        [Route("api/lists/caseStatuses")]
        public dynamic Get(string q, bool pending, bool registered, bool dead)
        {
            return _caseStatuses.Get(q, false, pending, registered, dead);
        }
    }
}