using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Dynamic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Attachment;
using Inprotech.Web.ContactActivities;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using ActivityAttachment = InprotechKaizen.Model.ContactActivities.ActivityAttachment;

namespace Inprotech.Web.Names.Details
{
    public class NameActivityAttachmentMaintenance : ActivityAttachmentMaintenanceBase
    {
        readonly IDbContext _dbContext;
        readonly IAttachmentMaintenance _attachmentMaintenance;
        readonly IActivityMaintenance _activityMaintenance;

        public NameActivityAttachmentMaintenance(IDbContext dbContext, IAttachmentMaintenance attachmentMaintenance, IActivityMaintenance activityMaintenance, IAttachmentContentLoader attachmentContentLoader, ITransactionRecordal transactionRecordal) : base(AttachmentFor.Name, attachmentMaintenance, activityMaintenance, dbContext, attachmentContentLoader, transactionRecordal)
        {
            _dbContext = dbContext;
            _attachmentMaintenance = attachmentMaintenance;
            _activityMaintenance = activityMaintenance;
        }

        public override async Task<ExpandoObject> ViewDetails(int? nameId, int? eventId = null, string actionKey = null)
        {
            dynamic result = await _activityMaintenance.ViewDetails();

            if (nameId.HasValue)
            {
                result.nameId = nameId;
                result.displayName = _dbContext.Set<Name>().Single(_ => _.Id == nameId).FormattedNameOrNull();
            }

            return result;
        }

        public override async Task<bool> DeleteAttachment(ActivityAttachmentModel activityAttachmentData)
        {
            if (activityAttachmentData == null) throw new ArgumentNullException(nameof(activityAttachmentData));
            if (activityAttachmentData.ActivityId == null) throw new ArgumentNullException(nameof(activityAttachmentData.ActivityId));

            return await base.DeleteAttachment(activityAttachmentData, true);
        }

        public override async Task<IEnumerable<ActivityAttachmentModel>> GetAttachments(int nameId, CommonQueryParameters param)
        {
            var attachments = await _dbContext.Set<ActivityAttachment>().Include(_ => _.Activity)
                                              .Where(_ => _.Activity.ContactNameId == nameId)
                                              .OrderBy(_ => _.ActivityId)
                                              .ThenBy(_ => _.SequenceNo)
                                              .AsPagedResultsAsync(param);

            if (attachments?.Data == null) throw new InvalidDataException(nameof(attachments));

            return attachments.Data.Select(_ => _attachmentMaintenance.ToAttachment(_, true));
        }
    }
}