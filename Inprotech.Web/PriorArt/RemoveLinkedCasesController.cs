using System;
using System.Collections.Generic;
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
using InprotechKaizen.Model.PriorArt;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Delete)]
    public class RemoveLinkedCasesController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ILinkedCaseSearch _linkedCaseSearch;

        public RemoveLinkedCasesController(IDbContext dbContext, ILinkedCaseSearch linkedCaseSearch)
        {
            _dbContext = dbContext;
            _linkedCaseSearch = linkedCaseSearch;
        }

        [HttpPost]
        [Route("api/priorart/linkedCases/remove")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "args.Request.CaseKeys")]
        public async Task<dynamic> RemoveLinkedCases([FromBody] RemovePriorArtSelection args)
        {
            if (args == null) throw new ArgumentNullException(nameof(args));
            if (args.Request.SourceDocumentId == null || (!args.Request.CaseKeys.Any() && !args.Request.IsSelectAll)) throw new HttpResponseException(HttpStatusCode.BadRequest);

            IQueryable<CaseSearchResult> caseSearchResults;
            if (args.Request.IsSelectAll)
            {
                caseSearchResults = _linkedCaseSearch.Citations(args.Request, args.QueryParams.Filters)
                                                     .Where(_ => !args.Request.ExceptCaseKeys.Contains(_.CaseKey) &&
                                                                 _.PriorArtId == args.Request.SourceDocumentId)
                                                     .Select(v => v.CaseSearchResult);
            }
            else
            {
                caseSearchResults = _dbContext.Set<CaseSearchResult>().Where(_ => args.Request.CaseKeys.Contains(_.CaseId) && _.PriorArtId == args.Request.SourceDocumentId);
            }
            
            if(!caseSearchResults.Any()) throw new HttpResponseException(HttpStatusCode.BadRequest);

            await _dbContext.DeleteAsync(caseSearchResults);

            return new
            {
                IsSuccessful = true
            };
        }
    }

    public class RemovePriorArtSelection
    {
        public RemoveLinkedCasesRequest Request { get; set; }
        public CommonQueryParameters QueryParams { get; set; }
    }

    public class RemoveLinkedCasesRequest : SearchRequest
    {
        public IEnumerable<int> CaseKeys { get; set; }
        public IEnumerable<int> ExceptCaseKeys { get; set; }
        public bool IsSelectAll { get; set; }
    }
}
