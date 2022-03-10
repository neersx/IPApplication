using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Attachment;
using Inprotech.Web.ContactActivities;

namespace Inprotech.Web.Names.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/attachment")]
    [RequiresAccessTo(ApplicationTask.MaintainNameAttachments, ApplicationTaskAccessLevel.None)]
    public class NameAttachmentMaintenanceController : ApiController
    {
        readonly ISiteControlReader _siteControl;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IActivityAttachmentMaintenance _attachmentMaintenance;

        public NameAttachmentMaintenanceController(IIndex<AttachmentFor, IActivityAttachmentMaintenance> attachmentMaintainanceTypes, ISiteControlReader siteControl, ITaskSecurityProvider taskSecurityProvider)
        {
            _siteControl = siteControl;
            _taskSecurityProvider = taskSecurityProvider;
            _attachmentMaintenance = attachmentMaintainanceTypes[AttachmentFor.Name];
        }

        [HttpGet]
        [Route("name/view/{id}")]
        [RequiresNameAuthorization(PropertyName = "id")]
        public async Task<dynamic> View(int? id)
        {
            var result = await _attachmentMaintenance.ViewDetails(id);
            result.AddRange(new[]
            {
                new KeyValuePair<string, object>("documentAttachmentsDisabled",_siteControl.Read<bool>(SiteControls.DocumentAttachmentsDisabled)),
                new KeyValuePair<string, object>("canAddAttachments", _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainNameAttachments, ApplicationTaskAccessLevel.Create))
            });
            return result;
        }

        [HttpGet]
        [Route("name/{id}")]
        [RequiresNameAuthorization(PropertyName = "id")]
        public async Task<ActivityAttachmentModel> Get(int? id, int activityId, int sequence)
        {
            return await _attachmentMaintenance.GetAttachment(activityId, sequence);
        }

        [HttpPut]
        [Route("new/name/{nameKey}")]
        [RequiresAccessTo(ApplicationTask.MaintainNameAttachments, ApplicationTaskAccessLevel.Create)]
        [AppliesToComponent(KnownComponents.Name)]
        [RequiresNameAuthorization(PropertyName = "nameKey")]
        public async Task<ActivityAttachmentModel> Create([FromBody] ActivityAttachmentModel activityAttachment, [FromUri] int nameKey)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            activityAttachment.ActivityNameId = nameKey;
            return await _attachmentMaintenance.InsertAttachment(activityAttachment);
        }

        [HttpPut]
        [Route("update/name/{nameKey}")]
        [RequiresNameAuthorization(PropertyName = "nameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainNameAttachments, ApplicationTaskAccessLevel.Modify)]
        [AppliesToComponent(KnownComponents.Name)]
        public async Task<ActivityAttachmentModel> Update([FromBody] ActivityAttachmentModel activityAttachment, [FromUri] int nameKey)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            activityAttachment.ActivityNameId = nameKey;
            return await _attachmentMaintenance.UpdateAttachment(activityAttachment);
        }

        [HttpDelete]
        [Route("delete/name/{nameKey}/{activityApi?}")]
        [RequiresNameAuthorization(PropertyName = "nameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainNameAttachments, ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.Name)]
        public async Task<bool> Delete([FromBody] ActivityAttachmentModel activityAttachment, [FromUri] int nameKey, [FromUri] bool? activityApi = false)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            activityAttachment.ActivityNameId = nameKey;
            var result = await _attachmentMaintenance.DeleteAttachment(activityAttachment, activityApi.Value);
            if (!result)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            return true;
        }
    }
}