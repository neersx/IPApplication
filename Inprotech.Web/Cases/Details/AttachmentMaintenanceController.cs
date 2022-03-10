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

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/attachment")]
    [RequiresAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.None)]
    public class CaseAttachmentMaintenanceController : ApiController
    {
        readonly IActivityAttachmentMaintenance _attachmentMaintenance;
        readonly ISiteControlReader _siteControl;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CaseAttachmentMaintenanceController(IIndex<AttachmentFor, IActivityAttachmentMaintenance> attachmentMaintainanceTypes, ISiteControlReader siteControl, ITaskSecurityProvider taskSecurityProvider)
        {
            _siteControl = siteControl;
            _taskSecurityProvider = taskSecurityProvider;
            _attachmentMaintenance = attachmentMaintainanceTypes[AttachmentFor.Case];
        }

        [HttpGet]
        [Route("case/view/{caseId}")]
        [RequiresCaseAuthorization(PropertyName = "caseId")]
        public async Task<dynamic> View(int caseId, int? eventKey = null, int? eventCycle = null, string actionKey = null)
        {
            var result = await _attachmentMaintenance.ViewDetails(caseId, eventKey, actionKey);
            result.AddRange(new[]
            {
                new KeyValuePair<string, object>("documentAttachmentsDisabled", _siteControl.Read<bool>(SiteControls.DocumentAttachmentsDisabled)),
                new KeyValuePair<string, object>("canAddAttachments", _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Create))
            });

            return result;
        }

        [HttpGet]
        [Route("case/{caseId}")]
        [RequiresCaseAuthorization]
        public async Task<ActivityAttachmentModel> Get(int caseId, int? activityId, int sequence)
        {
            if (activityId == null) throw new ArgumentNullException(nameof(activityId));

            return await _attachmentMaintenance.GetAttachment(activityId.Value, sequence);
        }

        [HttpPut]
        [Route("update/case/{caseKey}")]
        [RequiresCaseAuthorization]
        [RequiresAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Modify)]
        [AppliesToComponent(KnownComponents.Case)]
        public async Task<ActivityAttachmentModel> Update(int caseKey, [FromBody] ActivityAttachmentModel activityAttachment)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            activityAttachment.ActivityCaseId = caseKey;
            return await _attachmentMaintenance.UpdateAttachment(activityAttachment);
        }

        [HttpPut]
        [Route("new/case/{caseKey}")]
        [RequiresCaseAuthorization]
        [RequiresAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Create)]
        [AppliesToComponent(KnownComponents.Case)]
        public async Task<ActivityAttachmentModel> Create(int caseKey, [FromBody] ActivityAttachmentModel activityAttachment)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));

            activityAttachment.ActivityCaseId = caseKey;
            return await _attachmentMaintenance.InsertAttachment(activityAttachment);
        }

        [HttpDelete]
        [Route("delete/case/{caseKey}/{activityApi?}")]
        [RequiresCaseAuthorization]
        [RequiresAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.Case)]
        public async Task<bool> Delete(int caseKey, [FromBody] ActivityAttachmentModel activityAttachment, [FromUri] bool? activityApi = false)
        {
            if (activityAttachment == null) throw new ArgumentNullException(nameof(activityAttachment));
            activityAttachment.ActivityCaseId = caseKey;

            var result = await _attachmentMaintenance.DeleteAttachment(activityAttachment, !activityApi.Value);
            if (!result)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            return true;
        }
    }
}