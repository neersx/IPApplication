using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseViewOfficialNumbersController : ApiController
    {
        readonly ICaseViewOfficialNumbers _caseViewOfficialNumbers;
        readonly IExternalPatentInfoLinkResolver _externalPatentInfoLink;
        readonly IDbContext _dbContext;

        public CaseViewOfficialNumbersController(ICaseViewOfficialNumbers caseViewOfficialNumbers, IExternalPatentInfoLinkResolver externalPatentInfoLink, IDbContext dbContext)
        {
            _caseViewOfficialNumbers = caseViewOfficialNumbers;
            _externalPatentInfoLink = externalPatentInfoLink;
            _dbContext = dbContext;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/officialnumbers/ipoffice")]
        public async Task<IEnumerable<OfficialNumbersData>> GetIpOfficeNumbers(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                                  CommonQueryParameters qp = null)
        {
            var numbers = await _caseViewOfficialNumbers.IpOfficeNumbers(caseKey).ToArrayAsync();

            if (numbers.Any())
            {
                var caseRef = await _dbContext.Set<Case>().Where(_ => _.Id == caseKey).Select(_ => _.Irn).SingleOrDefaultAsync();
                var officialNumbersLinks = _externalPatentInfoLink.ResolveOfficialNumbers(caseRef, numbers.Where(_ => _.DocItemId.HasValue).Select(_ => _.DocItemId.Value).ToArray());
                foreach (var link in officialNumbersLinks)
                {
                    foreach (var number in numbers.Where(_ => _.DocItemId == link.Key))
                        number.ExternalInfoLink = link.Value;
                }
            }

            return numbers;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/officialnumbers/other")]
        public async Task<IEnumerable<OfficialNumbersData>> GetOtherNumbers(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                             CommonQueryParameters qp = null)
        {
            return await _caseViewOfficialNumbers.OtherNumbers(caseKey).ToArrayAsync();
        }
    }
}