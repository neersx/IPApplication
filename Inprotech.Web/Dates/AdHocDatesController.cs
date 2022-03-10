using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Dates
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/adhocdates")]
    public class AdHocDatesController : ApiController
    {
        readonly IAdHocDates _adHocDate;
        readonly ICaseAuthorization _caseAuthorization;

        public AdHocDatesController(IAdHocDates adHocDate,
                                        ICaseAuthorization caseAuthorization)
        {
            _adHocDate = adHocDate;
            _caseAuthorization = caseAuthorization;
        }

        [HttpGet]
        [Route("{id}")]
        [NoEnrichment]
        public AdHocDatePayload Get(int id)
        {
            return _adHocDate.Get(id);
        }

        [HttpDelete]
        [Route("{alertId}")]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        public dynamic Delete(long alertId)
        {
            return _adHocDate.Delete(alertId);
        }

        [HttpPost]
        [Route("finalise")]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.FinaliseAdHocDate, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> Finalise(FinaliseRequestModel finaliseRequestModel)
        {
            return await _adHocDate.Finalise(finaliseRequestModel);
        }

        [HttpPost]
        [Route("bulkfinalise")]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.FinaliseAdHocDate, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> BulkFinalise(BulkFinaliseRequestModel bulkFinaliseRequestModel)
        {
            return await _adHocDate.BulkFinalise(bulkFinaliseRequestModel);
        }

        [HttpPost]
        [Route("")]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainAdHocDate, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> CreateAdhocDate(AdhocSaveDetails[] saveAdhocDetails)
        {
            if (saveAdhocDetails == null || !saveAdhocDetails.Any())
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            var caseId = saveAdhocDetails[0].CaseId;
            if (caseId.HasValue)
            {
                var response = await _caseAuthorization.Authorize(caseId.Value, AccessPermissionLevel.Update);
                if (response.IsUnauthorized)
                {
                    throw new DataSecurityException(response.ReasonCode.CamelCaseToUnderscore());
                }
            }

            return await _adHocDate.CreateAdhocDate(saveAdhocDetails);
        }

        [HttpGet]
        [Route("viewdata/{alertId:int?}")]
        [NoEnrichment]
        public async Task<dynamic> ViewData(int? alertId = null)
        {
            return await _adHocDate.ViewData(alertId);
        }

        [HttpGet]
        [Route("caseeventdetails/{caseEventId}")]
        [NoEnrichment]
        public async Task<dynamic> CaseEventDetails(int caseEventId)
        {
            return await _adHocDate.CaseEventDetails(caseEventId);
        }

        [HttpGet]
        [Route("namedetails/{caseId}")]
        [NoEnrichment]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update)]
        public IEnumerable<Names> NameDetails(int caseId)
        {
            return _adHocDate.NameDetails(caseId);
        }

        [HttpGet]
        [Route("relationshipDetails/{caseId}/{nameTypeCode}/{relationshipCode}")]
        [NoEnrichment]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update)]
        public IEnumerable<Names> RelationshipDetails(int caseId,string nameTypeCode, string relationshipCode)
        {
            if (string.IsNullOrEmpty(nameTypeCode) && string.IsNullOrEmpty(relationshipCode))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }
            return _adHocDate.RelationshipDetails(caseId,nameTypeCode,relationshipCode);
        }

        [HttpPut]
        [Route("{alertId}")]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainAdHocDate, ApplicationTaskAccessLevel.Modify)]
        [RequiresCaseAuthorization(PropertyPath = "maintainAdhocDetails.CaseId")]
        public async Task<dynamic> MaintainAdhocDate(int? alertId, AdhocSaveDetails maintainAdhocDetails)
        {
            if (maintainAdhocDetails == null)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            if (alertId == null)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            var caseId = maintainAdhocDetails.CaseId;
            if (!caseId.HasValue) return await _adHocDate.MaintainAdhocDate(alertId.Value, maintainAdhocDetails);

            var response = await _caseAuthorization.Authorize(caseId.Value, AccessPermissionLevel.Update);
            if (response.IsUnauthorized)
                throw new DataSecurityException(response.ReasonCode.CamelCaseToUnderscore());

            return await _adHocDate.MaintainAdhocDate(alertId.Value, maintainAdhocDetails);
        }
    }
}