using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.IPPlatform.FileApp;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class RelatedCasesController : ApiController
    {
        readonly IRelatedCases _relatedCases;
        readonly IDbContext _dbContext;
        readonly IExternalPatentInfoLinkResolver _externalPatentInfoLink;
        readonly IFileInstructInterface _fileInstructInterface;
        readonly IAuthSettings _settings;

        public RelatedCasesController(
            IDbContext dbContext, 
            IRelatedCases relatedCases, 
            IExternalPatentInfoLinkResolver externalPatentInfoLink,
            IFileInstructInterface fileInstructInterface,
            IAuthSettings settings)
        {
            _relatedCases = relatedCases;
            _dbContext = dbContext;
            _externalPatentInfoLink = externalPatentInfoLink;
            _fileInstructInterface = fileInstructInterface;
            _settings = settings;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/relatedcases")]
        public async Task<PagedResults> GetRelatedCases(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp = null)
        {
            var relatedCases = await _relatedCases.Retrieve(caseKey);

            var relatedCasesData = relatedCases.OrderByProperty(qp)
                                   .AsPagedResults(qp);

            if (relatedCasesData.Data.Any())
            {
                var caseRef = await _dbContext.Set<Case>().Where(_ => _.Id == caseKey).Select(_ => _.Irn).SingleOrDefaultAsync();
                var officialNumbersLinks = _externalPatentInfoLink.ResolveRelatedCases(caseRef, relatedCasesData.Data
                                                                                                      .Where(_ => !string.IsNullOrEmpty(_.CountryCode)
                                                                                                                  && !string.IsNullOrEmpty(_.OfficialNumber))
                                                                                                      .Select(_ => (_.CountryCode, _.OfficialNumber))
                                                                                                      .ToArray());
                foreach (var link in officialNumbersLinks)
                {
                    foreach (var number in relatedCasesData.Data.Where(_ => _.CountryCode == link.Key.countryCode && _.OfficialNumber == link.Key.officialNumber))
                        number.ExternalInfoLink = link.Value;
                }
            }

            var filedCases = _settings.SsoEnabled
                ? await _fileInstructInterface.GetFiledCaseIdsFor(Request, caseKey)
                : new FiledCases();

            foreach (var i in relatedCasesData.Data)
            {
                if (i.CaseId == null) continue;

                i.IsFiled = filedCases.FiledCaseIds.Contains(i.CaseId.Value);
                i.CanViewInFile = (i.InternalReference != null || i.ClientReference != null) && filedCases.CanView;
            }

            return new PagedResults(relatedCasesData.Data, relatedCasesData.Pagination.Total);
        }
    }
}