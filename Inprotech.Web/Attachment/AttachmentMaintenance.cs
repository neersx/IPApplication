using System;
using System.Data.Entity;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.ContactActivities;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Attachment
{
    public interface IAttachmentMaintenance
    {
        Task<ActivityAttachmentModel> UpdateAttachment(ActivityAttachmentModel activityAttachmentData);
        Task<ActivityAttachmentModel> InsertAttachment(ActivityAttachmentModel activityAttachmentData);
        Task<bool> DeleteAttachment(ActivityAttachmentModel activityAttachmentData);
        ActivityAttachmentModel ToAttachment(ActivityAttachment attachment, bool forSearch = false);
    }

    public class AttachmentMaintenance : IAttachmentMaintenance
    {
        readonly IDbContext _dbContext;

        public AttachmentMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<ActivityAttachmentModel> UpdateAttachment(ActivityAttachmentModel activityAttachmentData)
        {
            if (activityAttachmentData == null) throw new ArgumentNullException(nameof(activityAttachmentData));

            var attachment = _dbContext.Set<ActivityAttachment>()
                                       .FirstOrDefault(_ => _.ActivityId == activityAttachmentData.ActivityId && _.SequenceNo == activityAttachmentData.SequenceNo);
            if (attachment == null)
            {
                throw new InvalidDataException(nameof(attachment));
            }

            attachment.AttachmentDescription = activityAttachmentData.AttachmentDescription;
            attachment.AttachmentName = activityAttachmentData.AttachmentName;
            attachment.AttachmentType = activityAttachmentData.AttachmentType.HasValue ? _dbContext.Set<TableCode>().Single(_ => _.Id == activityAttachmentData.AttachmentType.Value) : null;
            attachment.FileName = activityAttachmentData.FilePath;
            attachment.PublicFlag = activityAttachmentData.IsPublic ? 1 : 0;
            attachment.Language = activityAttachmentData.Language.HasValue ? _dbContext.Set<TableCode>().Single(_ => _.Id == activityAttachmentData.Language) : null;
            attachment.PageCount = activityAttachmentData.PageCount;

            await _dbContext.SaveChangesAsync();

            return ToAttachment(attachment);
        }

        public async Task<ActivityAttachmentModel> InsertAttachment(ActivityAttachmentModel activityAttachmentData)
        {
            if (activityAttachmentData == null) throw new ArgumentNullException(nameof(activityAttachmentData));
            if (activityAttachmentData.ActivityId == null) throw new ArgumentNullException(nameof(activityAttachmentData.ActivityId));
            if (activityAttachmentData.DocumentId.HasValue && string.IsNullOrWhiteSpace(activityAttachmentData.FileName)) throw new ArgumentNullException(nameof(activityAttachmentData));

            var activityId = activityAttachmentData.ActivityId.Value;
            var sequenceNo = await _dbContext.Set<ActivityAttachment>()
                                             .Where(_ => _.ActivityId == activityId)
                                             .Select(_ => _.SequenceNo)
                                             .DefaultIfEmpty(-1)
                                             .MaxAsync() + 1;

            var attachment = _dbContext.Set<ActivityAttachment>().Create();
            attachment.ActivityId = activityId;
            attachment.SequenceNo = sequenceNo;
            attachment.AttachmentName = activityAttachmentData.AttachmentName;
            attachment.AttachmentType = activityAttachmentData.AttachmentType.HasValue ? _dbContext.Set<TableCode>().Single(_ => _.Id == activityAttachmentData.AttachmentType.Value) : null;
            attachment.FileName = activityAttachmentData.DocumentId.HasValue ? Path.Combine(activityAttachmentData.FilePath, activityAttachmentData.FileName) : activityAttachmentData.FilePath;
            attachment.AttachmentDescription = activityAttachmentData.AttachmentDescription;
            attachment.PublicFlag = activityAttachmentData.IsPublic ? 1 : 0;
            attachment.Language = activityAttachmentData.Language.HasValue ? _dbContext.Set<TableCode>().Single(_ => _.Id == activityAttachmentData.Language) : null;
            attachment.PageCount = activityAttachmentData.PageCount;
            _dbContext.Set<ActivityAttachment>().Add(attachment);

            await _dbContext.SaveChangesAsync();

            return ToAttachment(attachment);
        }

        public async Task<bool> DeleteAttachment(ActivityAttachmentModel activityAttachmentData)
        {
            var attachment = _dbContext.Set<ActivityAttachment>().SingleOrDefault(_ => _.ActivityId == activityAttachmentData.ActivityId && _.SequenceNo == activityAttachmentData.SequenceNo);
            if (attachment == null)
            {
                return false;
            }

            _dbContext.Set<ActivityAttachment>().Remove(attachment);

            await _dbContext.SaveChangesAsync();

            return true;
        }

        public ActivityAttachmentModel ToAttachment(ActivityAttachment attachment, bool forSearch = false)
        {
            var activityAttachmentModel = attachment.ToModel();
            if (forSearch)
            {
                activityAttachmentModel.EventDescription = !attachment.Activity.EventId.HasValue
                    ? string.Empty
                    : (from e in _dbContext.Set<Event>()
                       join oa in _dbContext.Set<OpenAction>() on attachment.Activity.CaseId equals oa.CaseId
                       join ec in _dbContext.Set<ValidEvent>() on oa.CriteriaId equals ec.CriteriaId
                       where e.Id == attachment.Activity.EventId && ec.EventId == e.Id
                       select ec.Description ?? e.Description).FirstOrDefault();
            }

            return activityAttachmentModel;
        }
    }

    public enum AttachmentFor
    {
        Case,
        Name,
        ContactActivity,
        PriorArt
    }
}