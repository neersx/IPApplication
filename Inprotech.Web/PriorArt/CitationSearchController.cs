using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Innography;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    public class CitationSearchController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPatentScoutUrlFormatter _referenceFormatter;

        public CitationSearchController(IDbContext dbContext, IPatentScoutUrlFormatter referenceFormatter)
        {
            _dbContext = dbContext;
            _referenceFormatter = referenceFormatter;
        }

        [HttpGet]
        [Route("api/priorart/citations/search")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "args.CaseKey")]
        public async Task<PagedResults<ExistingPriorArtMatch>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "args")]
                                          SearchRequest args, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                          CommonQueryParameters queryParams = null)
        {
            var citations = args.IsSourceDocument.GetValueOrDefault()
                ? _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                            .Where(_ => _.IsSourceDocument && _.Id == args.SourceDocumentId)
                            .SelectMany(_ => _.CitedPriorArt).ToList()
                : _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                            .Where(_ => !_.IsSourceDocument && _.Id == args.SourceDocumentId)
                            .SelectMany(_ => _.SourceDocuments).ToList();
            var pagedResult = citations.Select(_ => new ExistingPriorArtMatch
            {
                ReferenceLink = _referenceFormatter.CreatePatentScoutReferenceLink(_.CorrelationId, new SearchResultOptions().ReferenceHandling.IsIpPlatformSession),
                Reference = _.OfficialNumber,
                Description = _.Description,
                Id = _.Id.ToString(),
                CountryName = _.Country?.Name,
                Kind = _.Kind,
                Title = _.Title,
                Name = _.Name,
                Citation = _.Citation,
                IsIpoIssued = _.IsIpDocument.GetValueOrDefault(),
                SourceType = _.SourceType?.Name,
                IssuingJurisdiction = _.IssuingCountry?.Name,
                ReportReceived = _.ReportReceived,
                ReportIssued = _.ReportIssued,
                Publication = _.Publication,
                Comments = _.Comments
            }).AsQueryable().AsOrderedPagedResults(queryParams ?? CommonQueryParameters.Default);
            return pagedResult;
        }
    }
}   
