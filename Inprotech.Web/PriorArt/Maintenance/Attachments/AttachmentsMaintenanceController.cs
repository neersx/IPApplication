using System;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.ContactActivities;

namespace Inprotech.Web.PriorArt.Maintenance.Attachments
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/attachment")]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.None)]
    public class AttachmentsMaintenanceController : ApiController
    {
        readonly IActivityAttachmentMaintenance _attachmentMaintenance;

        public AttachmentsMaintenanceController(IActivityAttachmentMaintenance attachmentMaintainanceTypes)
        {
            _attachmentMaintenance = attachmentMaintainanceTypes;
        }

        [HttpGet]
        [Route("priorart/view/{priorartId}")]
        public async Task<dynamic> View(int priorArtId, int? caseId = null)
        {
            dynamic result = await _attachmentMaintenance.ViewDetails(caseId);
            result.priorArtId = priorArtId;

            return result;
        }

        [HttpPut]
        [Route("new/priorart/{priorartId}")]
        [RequiresAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.Create)]
        [AppliesToComponent(KnownComponents.PriorArt)]
        public async Task<ActivityAttachmentModel> Create(int priorartId, [FromBody] ActivityAttachmentModel activityAttachment)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            activityAttachment.PriorArtId = priorartId;
            return await _attachmentMaintenance.InsertAttachment(activityAttachment);
        }

        [HttpGet]
        [Route("priorart/{priorartId}")]
        public async Task<dynamic> PriorArtAttachmentDetails(int priorartId, int activityId, int sequence)
        {
            dynamic result = await _attachmentMaintenance.GetAttachment(activityId, sequence);

            return result;
        }

        [HttpPut]
        [Route("update/priorArt/{priorartId}")]
        [RequiresAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.Modify)]
        [AppliesToComponent(KnownComponents.PriorArt)]
        public async Task<ActivityAttachmentModel> Update(int priorartId, [FromBody] ActivityAttachmentModel activityAttachment)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            activityAttachment.PriorArtId = priorartId;
            return await _attachmentMaintenance.UpdateAttachment(activityAttachment);
        }

        [HttpDelete]
        [Route("delete/priorArt/{priorArtId}/{activityApi?}")]
        [RequiresAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.PriorArt)]
        public async Task<bool> Delete(int priorArtId, [FromBody] ActivityAttachmentModel activityAttachment, [FromUri] bool? activityApi = false)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            var result = await _attachmentMaintenance.DeleteAttachment(activityAttachment, !activityApi.Value);
            if (!result)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            return true;
        }
    }
}