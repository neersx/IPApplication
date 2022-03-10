using System;
using System.Web.Http;
using Inprotech.Web.Search.CaseSupportData;

namespace Inprotech.Web.Lists
{
    [Authorize]
    public class RenewalStatusesController : ApiController
    {
        readonly IRenewalStatuses _renewalStatuses;

        public RenewalStatusesController(IRenewalStatuses renewalStatuses)
        {
            if(renewalStatuses == null) throw new ArgumentNullException("renewalStatuses");

            _renewalStatuses = renewalStatuses;
        }

        [Route("api/lists/renewalStatuses")]
        public dynamic Get(string q, bool pending, bool registered, bool dead)
        {
            return _renewalStatuses.Get(q, pending, registered, dead);
        }
    }
}