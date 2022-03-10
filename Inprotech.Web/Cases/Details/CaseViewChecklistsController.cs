using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseViewChecklistController : ApiController
    {
        readonly ICaseChecklistDetails _caseChecklistDetails;
        readonly ICommonQueryService _commonQueryService;

        public CaseViewChecklistController(ICaseChecklistDetails caseChecklistDetails, ICommonQueryService commonQueryService)
        {
            _caseChecklistDetails = caseChecklistDetails;
            _commonQueryService = commonQueryService;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/checklist-types")]
        public async Task<ChecklistTypeAndSelectedOne> GetChecklistTypes(int caseKey)
        {
            return await _caseChecklistDetails.GetChecklistTypes(caseKey);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/checklists")]
        public async Task<PagedResults> GetChecklistData(int caseKey, int? checklistCriteriaKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp = null)
        {           
            var results = (await _caseChecklistDetails.GetChecklistData(caseKey, checklistCriteriaKey)).ToArray();
            return results.Length > 0 ? new PagedResults(_commonQueryService.GetSortedPage(results, qp), results.Length) : new PagedResults(results, 0);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/checklists-hybrid")]
        public async Task<CaseChecklistQuestions[]> GetChecklistDataHybrid(int caseKey, int? checklistCriteriaKey)
        {           
            var results = (await _caseChecklistDetails.GetChecklistData(caseKey, checklistCriteriaKey)).ToArray();
            return results;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/checklistsDocuments")]
        public async Task<ChecklistDocuments[]> GetChecklistGeneralDocuments(int caseKey, int checklistCriteriaKey)
        {           
            var results = (await _caseChecklistDetails.GetChecklistDocuments(caseKey, checklistCriteriaKey)).ToArray();
            return results;
        }
    }
}