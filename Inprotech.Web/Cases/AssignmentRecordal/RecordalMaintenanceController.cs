using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify)]
    [RoutePrefix("api/case")]
    public class RecordalMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IRecordalMaintenance _recordalMaintenance;

        public RecordalMaintenanceController(IDbContext dbContext, IRecordalMaintenance recordalMaintenance)
        {
            _dbContext = dbContext;
            _recordalMaintenance = recordalMaintenance;
        }
        
        [HttpPost]
        [Route("requestRecordal")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "model.CaseId")]
        public async Task<IEnumerable<RecordalRequestData>> GetRequestRecordal([FromBody] RecordalRequest model)
        {
            if (model == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var @case = _dbContext.Set<Case>().SingleOrDefault(v => v.Id == model.CaseId);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return await _recordalMaintenance.GetAffectedCasesForRequestRecordal(model);
        }

        [HttpPost]
        [Route("saveRecordal")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "model.CaseId")]
        public async Task<dynamic> SaveRequestRecordal([FromBody] SaveRecordalRequest model)
        {
            if (model == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var @case = _dbContext.Set<Case>().SingleOrDefault(v => v.Id == model.CaseId);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return await _recordalMaintenance.SaveRequestRecordal(model);
        }
    }
}
