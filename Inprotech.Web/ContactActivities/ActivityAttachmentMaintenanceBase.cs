using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Dynamic;
using System.IO;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Attachment;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.ContactActivities
{
    public interface IActivityAttachmentMaintenance
    {
        Task<ExpandoObject> ViewDetails(int? id, int? eventId = null, string actionKey = null);
        Task<ActivityAttachmentModel> GetAttachment(int activityKey, int sequenceNo);
        Task<ActivityAttachmentModel> InsertAttachment(ActivityAttachmentModel activityAttachmentData);
        Task<ActivityAttachmentModel> UpdateAttachment(ActivityAttachmentModel activityActivityAttachment);
        Task<bool> DeleteAttachment(ActivityAttachmentModel activityAttachmentData, bool deleteActivity = true);
        Task<IEnumerable<ActivityAttachmentModel>> GetAttachments(int caseOrNameId, CommonQueryParameters param);
    }

    public abstract class ActivityAttachmentMaintenanceBase : IActivityAttachmentMaintenance
    {
        readonly AttachmentFor _attachmentFor;
        readonly IAttachmentMaintenance _attachmentMaintenance;
        readonly IActivityMaintenance _activityMaintenance;
        readonly IDbContext _dbContext;
        readonly IAttachmentContentLoader _attachmentContentLoader;
        readonly ITransactionRecordal _transactionRecordal;

        public ActivityAttachmentMaintenanceBase(AttachmentFor attachmentFor, IAttachmentMaintenance attachmentMaintenance, IActivityMaintenance activityMaintenance, IDbContext dbContext, IAttachmentContentLoader attachmentContentLoader, ITransactionRecordal transactionRecordal)
        {
            _attachmentFor = attachmentFor;
            _attachmentMaintenance = attachmentMaintenance;
            _activityMaintenance = activityMaintenance;
            _dbContext = dbContext;
            _attachmentContentLoader = attachmentContentLoader;
            _transactionRecordal = transactionRecordal;
        }

        void RecordTransaction(int? key)
        {
            if (!key.HasValue)
                return;

            switch (_attachmentFor)
            {
                case AttachmentFor.Case:
                    _transactionRecordal.RecordTransactionForCase(key.Value, CaseTransactionMessageIdentifier.AmendedCase, component: KnownComponents.Case);
                    break;
                case AttachmentFor.Name:
                    _transactionRecordal.RecordTransactionForName(key.Value, NameTransactionMessageIdentifier.AmendedName);
                    break;
                case AttachmentFor.ContactActivity:
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        public abstract Task<ExpandoObject> ViewDetails(int? id, int? eventId = null, string actionKey = null);

        public virtual async Task<ActivityAttachmentModel> GetAttachment(int activityKey, int sequenceNo)
        {
            var attachment = await _dbContext.Set<ActivityAttachment>()
                                             .Include(_ => _.Activity)
                                             .FirstOrDefaultAsync(_ => _.ActivityId == activityKey && _.SequenceNo == sequenceNo);
            if (attachment == null) throw new InvalidDataException(nameof(attachment));

            var model = attachment.ToModel();
            if (_attachmentContentLoader.TryLoadAttachmentContent(activityKey, sequenceNo, out _))
            {
                model.IsFileStoredInDb = true;
            }

            return model;
        }

        public virtual async Task<ActivityAttachmentModel> InsertAttachment(ActivityAttachmentModel activityAttachmentData)
        {
            if (activityAttachmentData == null) throw new ArgumentNullException(nameof(activityAttachmentData));

            var activityId = activityAttachmentData.ActivityId;

            using (var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                RecordTransaction(activityAttachmentData.GetKey(_attachmentFor));

                if (!activityId.HasValue)
                {
                    var activity = await _activityMaintenance.InsertActivity(activityAttachmentData.ActivityNameId, activityAttachmentData.ActivityCaseId, activityAttachmentData);
                    activityAttachmentData.ActivityId = activity.Id;
                }

                var activityAttachment = await _attachmentMaintenance.InsertAttachment(activityAttachmentData);
                tsc.Complete();

                return activityAttachment;
            }
        }

        public virtual async Task<ActivityAttachmentModel> UpdateAttachment(ActivityAttachmentModel activityActivityAttachment)
        {
            if (activityActivityAttachment == null) throw new ArgumentNullException(nameof(activityActivityAttachment));
            if (activityActivityAttachment.ActivityId == null) throw new ArgumentNullException(nameof(activityActivityAttachment.ActivityId));

            using (var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                RecordTransaction(activityActivityAttachment.GetKey(_attachmentFor));

                await _activityMaintenance.UpdateActivity(activityActivityAttachment.ActivityId.Value, activityActivityAttachment);
                var activityAttachment = await _attachmentMaintenance.UpdateAttachment(activityActivityAttachment);

                tsc.Complete();
                return activityAttachment;
            }
        }

        public async Task<bool> DeleteAttachment(ActivityAttachmentModel activityAttachmentData, bool deleteActivity)
        {
            if (activityAttachmentData == null) throw new ArgumentNullException(nameof(activityAttachmentData));
            if (activityAttachmentData.ActivityId == null) throw new ArgumentNullException(nameof(activityAttachmentData.ActivityId));

            using (var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                RecordTransaction(activityAttachmentData.GetKey(_attachmentFor));
                var attachmentDeleted = await _attachmentMaintenance.DeleteAttachment(activityAttachmentData);

                if (attachmentDeleted && deleteActivity)
                {
                    await _activityMaintenance.TryDelete(activityAttachmentData.ActivityId.Value);
                }

                tsc.Complete();
                return attachmentDeleted;
            }
        }

        public abstract Task<bool> DeleteAttachment(ActivityAttachmentModel activityAttachmentData);
        public abstract Task<IEnumerable<ActivityAttachmentModel>> GetAttachments(int caseOrNameId, CommonQueryParameters param);
    }

    public static class ActivityAttachmentEx
    {
        public static ActivityAttachmentModel ToModel(this ActivityAttachment attachment)
        {
            var result = new ActivityAttachmentModel
            {
                ActivityId = attachment.ActivityId,
                SequenceNo = attachment.SequenceNo,
                AttachmentName = attachment.AttachmentName,
                AttachmentType = attachment.AttachmentType?.Id,
                AttachmentTypeDescription = attachment.AttachmentType?.Name,
                FilePath = attachment.FileName,
                IsPublic = attachment.PublicFlag == 1,
                Language = attachment.Language?.Id,
                LanguageDescription = attachment.Language?.Name,
                PageCount = attachment.PageCount,
                AttachmentDescription = attachment.AttachmentDescription
            };
            if (attachment.Activity != null)
            {
                result.ActivityCaseId = attachment.Activity.CaseId;
                result.ActivityNameId = attachment.Activity.ContactNameId;
                result.ActivityCategoryId = attachment.Activity.ActivityCategoryId;
                result.ActivityType = attachment.Activity.ActivityTypeId;
                result.ActivityDate = attachment.Activity.ActivityDate;
                result.EventId = attachment.Activity.EventId;
                result.EventCycle = attachment.Activity.Cycle;
            }

            return result;
        }
    }

    public class ActivityAttachmentModel
    {
        public int? DocumentId { get; set; }
        public int? ActivityId { get; set; }
        public int ActivityCategoryId { get; set; }
        public DateTime? ActivityDate { get; set; }
        public int ActivityType { get; set; }
        public short? EventCycle { get; set; }
        public int? EventId { get; set; }
        public string EventDescription { get; set; }
        public bool EventIsCyclic { get; set; }
        public bool IsCaseEvent { get; set; }
        public int CurrentCycle { get; set; }
        public int? ActivityCaseId { get; set; }
        public int? ActivityNameId { get; set; }
        public int? SequenceNo { get; set; }
        public string AttachmentName { get; set; }
        public int? AttachmentType { get; set; }
        public string AttachmentTypeDescription { get; set; }
        public string FilePath { get; set; }
        public string FileName { get; set; }
        public string AttachmentDescription { get; set; }
        public bool IsPublic { get; set; }
        public int? Language { get; set; }
        public string LanguageDescription { get; set; }
        public int? PageCount { get; set; }
        public bool IsFileStoredInDb { get; set; }
        public int? PriorArtId { get; set; }

        public int? GetKey(AttachmentFor attachmentFor)
        {
            switch (attachmentFor)
            {
                case AttachmentFor.Case:
                    return ActivityCaseId;

                case AttachmentFor.Name:
                    return ActivityNameId;

                case AttachmentFor.ContactActivity: break;

                default:
                    throw new ArgumentOutOfRangeException(nameof(AttachmentFor), attachmentFor, null);
            }

            return null;
        }
    }
}