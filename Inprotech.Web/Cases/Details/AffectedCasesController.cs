using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class AffectedCasesController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IAffectedCases _affectedCases;
        readonly IAffectedCasesSetAgent _setAgent;
        readonly IAffectedCasesMaintenance _affectedCasesMaintenance;

        public AffectedCasesController(IDbContext dbContext, IAffectedCases affectedCases, IAffectedCasesSetAgent setAgent, IAffectedCasesMaintenance affectedCasesMaintenance)
        {
            _dbContext = dbContext;
            _affectedCases = affectedCases;
            _setAgent = setAgent;
            _affectedCasesMaintenance = affectedCasesMaintenance;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/affectedCasesColumns")]
        public async Task<IEnumerable<SearchResult.Column>> GetAffectedCasesColumns(int caseKey)
        {
            var @case = _dbContext.Set<Case>().SingleOrDefault(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var affectedCasesColumns = await _affectedCases.GetAffectedCasesColumns(caseKey);
            return affectedCasesColumns;
        }

        [HttpPost]
        [RequiresCaseAuthorization]
        [RequiresAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify)]
        [Route("{caseKey:int}/deleteAffectedCases")]
        public async Task<dynamic> DeleteAffectedCases(int caseKey, DeleteAffectedCaseModel affectedCaseModel)
        {
            var @case = _dbContext.Set<Case>().SingleOrDefault(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var result = await _affectedCasesMaintenance.DeleteAffectedCases(caseKey, affectedCaseModel);
            return result;
        }

        [HttpPost]
        [RequiresCaseAuthorization]
        [RequiresAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify)]
        [Route("{caseKey:int}/clearAffectedCaseAgent")]
        public async Task<dynamic> ClearAffectedCases(int caseKey, DeleteAffectedCaseModel affectedCaseModel)
        {
            var @case = _dbContext.Set<Case>().SingleOrDefault(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var result = await _setAgent.ClearAgentForAffectedCases(caseKey, affectedCaseModel);
            return result;
        }

        [Route("{caseKey:int}/affectedCases")]
        [RequiresCaseAuthorization]
        public async Task<SearchResult> GetAffectedCases(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp = null,
                                                         [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "filter")] AffectedCasesFilterModel filter = null)
        {
            var @case = _dbContext.Set<Case>().SingleOrDefault(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var qp1 = qp ?? new CommonQueryParameters();

            return await _affectedCases.GetAffectedCases(caseKey, qp1, filter);
        }

        [Route("affectedCases/setAgent")]
        [HttpPost]
        [RequiresNameAuthorization(PropertyPath = "model.AgentId")]
        [RequiresCaseAuthorization(PropertyPath = "model.MainCaseId")]
        [RequiresAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> SetAgentForAffectedCases(AffectedCasesAgentModel model)
        {
            if (model == null) throw new ArgumentNullException();
            return await _setAgent.SetAgentForAffectedCases(model);
        }

        [HttpPost]
        [Route("affectedCaseValidation")]
        [RequiresAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify)]
        public async Task<IEnumerable<Inprotech.Web.Picklists.Case>> AddAffectedCaseValidation(ExternalAffectedCaseValidateModel model)
        {
            if (model == null || string.IsNullOrWhiteSpace(model.Country) || string.IsNullOrWhiteSpace(model.OfficialNo)) return null;
            return await _affectedCasesMaintenance.AddAffectedCaseValidation(model);

        }

        [HttpPost]
        [Route("recordalAffectedCase/save")]
        [RequiresAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify)]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "request.CaseId")]
        public async Task<dynamic> SubmitRecordalAffectedCases([FromBody] RecordalAffectedCaseRequest request)
        {
            if (request == null) return BadRequest();

            await _affectedCasesMaintenance.AddRecordalAffectedCases(request);
            return Ok();
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("getCaseRefAndNameType/{caseKey:int}")]
        public dynamic GetCaseReference(int caseKey)
        {
            return _affectedCases.GetCaseRefAndNameType(caseKey);
        }
    }

    public class ExternalAffectedCaseValidateModel
    {
        public string Country { get; set; }
        public string OfficialNo { get; set; }
    }

    public class DeleteAffectedCaseModel
    {
        public List<string> SelectedRowKeys { get; set; }
        public List<string> DeSelectedRowKeys { get; set; }
        public bool IsAllSelected { get; set; }
        public AffectedCasesFilterModel Filter { get; set; }
        public bool ClearCaseNameAgent { get; set; }
    }
    public class AffectedCasesFilterModel
    {
        public int? StepNo { get; set; }
        public int? OwnerId { get; set; }
        public string CaseReference { get; set; }
        public int? RecordalTypeNo { get; set; }
        public string[] Jurisdictions { get; set; }
        public string[] CaseStatus { get; set; }
        public string[] RecordalStatus { get; set; }
    }

    public class RecordalAffectedCaseRequest
    {
        public int CaseId { get; set; }
        public int[] RelatedCases { get; set; }
        public string Jurisdiction { get; set; }
        public string OfficialNo { get; set; }
        public IEnumerable<RecordalStepAddModel> RecordalSteps { get; set; }
    }

    public class RecordalStepAddModel
    {
        public int RecordalStepSequence { get; set; }
        public int RecordalTypeNo { get; set; }
    }
}
