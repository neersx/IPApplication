using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Attachment;

namespace Inprotech.Web.ContactActivities
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/attachment")]
    [RequiresAccessTo(ApplicationTask.MaintainContactActivityAttachment, ApplicationTaskAccessLevel.None)]
    public class AttachmentMaintenanceController : ApiController
    {
        readonly IActivityMaintenance _activityMaintenance;
        readonly IIndex<AttachmentFor, IActivityAttachmentMaintenance> _attachmentMaintainanceTypes;
        readonly IActivityAttachmentMaintenance _attachmentMaintenance;
        readonly ISiteControlReader _siteControl;

        public AttachmentMaintenanceController(IIndex<AttachmentFor, IActivityAttachmentMaintenance> attachmentMaintainanceTypes, IActivityMaintenance activityMaintenance, ISiteControlReader siteControl)
        {
            _attachmentMaintainanceTypes = attachmentMaintainanceTypes;
            _attachmentMaintenance = attachmentMaintainanceTypes[AttachmentFor.ContactActivity];
            _activityMaintenance = activityMaintenance;
            _siteControl = siteControl;
        }

        [HttpGet]
        [Route("activity/view/{activityId}")]
        public async Task<dynamic> View(int activityId)
        {
            var activityDetails = await _activityMaintenance.GetActivity(activityId);

            dynamic viewDetails = null;
            if (activityDetails.ActivityCaseId.HasValue)
            {
                viewDetails = await _attachmentMaintainanceTypes[AttachmentFor.Case].ViewDetails(activityDetails.ActivityCaseId.Value, activityDetails.EventId);
            }

            if (activityDetails.ActivityNameId.HasValue)
            {
                viewDetails = await _attachmentMaintainanceTypes[AttachmentFor.Name].ViewDetails(activityDetails.ActivityNameId);
            }

            if (viewDetails != null)
            {
                viewDetails.activityDetails = activityDetails;
                return viewDetails;
            }

            dynamic details = await _attachmentMaintenance.ViewDetails(activityId);
            details.activityDetails = activityDetails;
            details.documentAttachmentsDisabled = _siteControl.Read<bool>(SiteControls.DocumentAttachmentsDisabled);

            return details;
        }

        [HttpGet]
        [Route("activity")]
        public async Task<ActivityAttachmentModel> Get(int activityId, int sequence)
        {
            return await _attachmentMaintenance.GetAttachment(activityId, sequence);
        }

        [HttpPut]
        [Route("update/activity")]
        public async Task<ActivityAttachmentModel> Update([FromBody] ActivityAttachmentModel activityAttachment)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            return await _attachmentMaintenance.UpdateAttachment(activityAttachment);
        }

        [HttpPut]
        [Route("new/activity")]
        public async Task<ActivityAttachmentModel> Create([FromBody] ActivityAttachmentModel activityAttachment)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            return await _attachmentMaintenance.InsertAttachment(activityAttachment);
        }

        [HttpDelete]
        [Route("delete/activity")]
        public async Task<bool> Delete([FromBody] ActivityAttachmentModel activityAttachment)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            var result = await _attachmentMaintenance.DeleteAttachment(activityAttachment, false);
            if (!result)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            return true;
        }
    }
}