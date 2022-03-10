using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseViewRenewalsController : ApiController
    {
        readonly ICaseRenewalDetails _caseRenewalDetails;

        public CaseViewRenewalsController(ICaseRenewalDetails caseRenewalDetails)
        {
            _caseRenewalDetails = caseRenewalDetails;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/renewals")]
        public async Task<CaseRenewalData> GetRenewalDetails(int caseKey, int screenCriteriaKey)
        {
            return await _caseRenewalDetails.GetRenewalDetails(caseKey, screenCriteriaKey);
        }
    }
}