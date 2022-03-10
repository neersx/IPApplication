using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class RecordalStepsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IRecordalSteps _recordalSteps;
        readonly IRecordalStepsUpdater _recordalStepsUpdater;

        public RecordalStepsController(IDbContext dbContext, IRecordalSteps recordalSteps, IRecordalStepsUpdater recordalStepsUpdater)
        {
            _dbContext = dbContext;
            _recordalSteps = recordalSteps;
            _recordalStepsUpdater = recordalStepsUpdater;
        }

        [Route("{caseKey:int}/recordalSteps")]
        [RequiresCaseAuthorization]
        public async Task<IEnumerable<CaseRecordalStep>> GetRecordalSteps(int caseKey)
        {
            var @case = await _dbContext.Set<Case>().SingleOrDefaultAsync(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return await _recordalSteps.GetRecordalSteps(caseKey);
        }

        [Route("{caseKey:int}/recordalStep/{id:int}/recordalType/{recordalType:int}")]
        [RequiresCaseAuthorization]
        public async Task<IEnumerable<CaseRecordalStepElement>> GetRecordalStepElement(int caseKey, int id, int recordalType)
        {
            var @case = await _dbContext.Set<Case>().SingleOrDefaultAsync(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var recordalStep = await _dbContext.Set<RecordalStep>().SingleOrDefaultAsync(_ => _.CaseId == caseKey && _.Id == id && _.TypeId == recordalType) ??
                               new RecordalStep { CaseId = @caseKey, Id = id, TypeId = recordalType };

            return await _recordalSteps.GetRecordalStepElement(caseKey, recordalStep);
        }

        [Route("recordalStep/getCurrentAddress/{nameKey:int}")]
        [RequiresNameAuthorization]
        public async Task<CurrentAddress> GetCurrentAddress(int nameKey)
        {
            var @name = await _dbContext.Set<Name>().SingleOrDefaultAsync(v => v.Id == nameKey);
            if (@name == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return await _recordalSteps.GetCurrentAddress(nameKey);
        }

        [HttpPost]
        [Route("recordalSteps/save")]
        public async Task<dynamic> SubmitRecordalSteps([FromBody] IEnumerable<CaseRecordalStep> request)
        {
            var caseRecordalSteps = request as CaseRecordalStep[] ?? request.ToArray();
            var errors = _recordalStepsUpdater.Validate(caseRecordalSteps).ToArray();
            if (errors.Any())
            {
                return errors.AsErrorResponse();
            }

            await _recordalStepsUpdater.SubmitRecordalStep(caseRecordalSteps);
            return Ok();
        }
    }
}
