using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Attachment;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.ContactActivities
{
    public class ActivityAttachmentMaintenance : ActivityAttachmentMaintenanceBase
    {
        readonly IActivityMaintenance _activityMaintenance;

        public ActivityAttachmentMaintenance(IAttachmentMaintenance attachmentMaintenance, IActivityMaintenance activityMaintenance, IDbContext dbContext, IAttachmentContentLoader attachmentContentLoader, ITransactionRecordal transactionRecordal) : base(AttachmentFor.ContactActivity, attachmentMaintenance, activityMaintenance, dbContext, attachmentContentLoader, transactionRecordal)
        {
            _activityMaintenance = activityMaintenance;
        }

        public override async Task<ExpandoObject> ViewDetails(int? activityId, int? eventId = null, string actionKey = null)
        {
            return await _activityMaintenance.ViewDetails();
        }

        public override Task<bool> DeleteAttachment(ActivityAttachmentModel activityAttachmentData)
        {
            return base.DeleteAttachment(activityAttachmentData, false);
        }

        public override Task<IEnumerable<ActivityAttachmentModel>> GetAttachments(int caseOrNameId, CommonQueryParameters param)
        {
            throw new NotImplementedException();
        }
    }
}