using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt.Maintenance
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Modify)]
    public class UpdatePriorArtStatusController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _getDate;
        readonly ILinkedCaseSearch _linkedCaseSearch;

        public UpdatePriorArtStatusController(IDbContext dbContext, Func<DateTime> getDate, ILinkedCaseSearch linkedCaseSearch)
        {
            _dbContext = dbContext;
            _getDate = getDate;
            _linkedCaseSearch = linkedCaseSearch;
        }

        [HttpPost]
        [Route("api/priorart/linkedCases/update-status")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "args.Request.CaseKeys")]
        public async Task<dynamic> UpdatePriorArtStatus([FromBody] UpdatePriorArtStatusSelection args)
        {
            if (args == null) throw new ArgumentNullException(nameof(args));
            if (!args.Request.CaseKeys.Any() && !args.Request.IsSelectAll) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var now = _getDate();

            IQueryable<CaseSearchResult> priorarts;
            if (args.Request.IsSelectAll)
            {
                priorarts = _linkedCaseSearch.Citations(args.Request, args.QueryParams.Filters).Where(_ => !args.Request.ExceptCaseKeys.Contains(_.CaseKey) && _.PriorArtId == args.Request.SourceDocumentId)
                                             .Select(v => v.CaseSearchResult);
            }
            else
            {
                priorarts = _dbContext.Set<CaseSearchResult>().Where(_ => args.Request.CaseKeys.Contains(_.CaseId) && _.PriorArtId == args.Request.SourceDocumentId);
            }
            
            await _dbContext.UpdateAsync(priorarts, _ => new CaseSearchResult
            {
                StatusId = args.Request.ClearStatus ? null : args.Request.Status,
                UpdateDate = now
            });

            return new
            {
                IsSuccessful = true
            };
        }
    }

    public class UpdatePriorArtStatusSelection
    {
        public UpdatePriorArtStatusRequest Request { get; set; }
        public CommonQueryParameters QueryParams { get; set; }
    }

    public class UpdatePriorArtStatusRequest : SearchRequest
    {
        public int[] CaseKeys { get; set; }
        public int? Status { get; set; }
        public bool ClearStatus { get; set; }
        public int[] ExceptCaseKeys { get; set; }
        public bool IsSelectAll { get; set; }
    }
}
