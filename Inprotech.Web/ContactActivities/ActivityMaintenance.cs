using System;
using System.Data.Entity;
using System.Dynamic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Configuration.Extensions;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.ContactActivities
{
    public interface IActivityMaintenance
    {
        Task<ExpandoObject> ViewDetails();
        Task<ActivityDetails> GetActivity(int activityId);
        Task<Activity> InsertActivity(int? nameNo, int? caseId, ActivityAttachmentModel details);
        Task<Activity> UpdateActivity(int activityId, ActivityAttachmentModel details);
        Task<bool> TryDelete(int activityId);
    }

    public class ActivityMaintenance : IActivityMaintenance
    {
        readonly IAttachmentSettings _attachmentSettings;
        readonly IDbContext _dbContext;
        readonly IDmsSettingsProvider _dmsSettings;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public ActivityMaintenance(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator,
            IAttachmentSettings attachmentSettings, IDmsSettingsProvider dmsSettings, ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
            _attachmentSettings = attachmentSettings;
            _dmsSettings = dmsSettings;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public async Task<ExpandoObject> ViewDetails()
        {
            var required = new[]
            {
                (int) TableTypes.ContactActivityType,
                (int) TableTypes.ContactActivityCategory
            };
            var selectionAvailable = await _dbContext.Set<TableCode>()
                                                     .Where(tc => required.Contains(tc.TableTypeId))
                                                     .ToArrayAsync();

            var settings = await _attachmentSettings.Resolve();
            var hasDmsSettings = await _dmsSettings.HasSettings();
            dynamic result = new ExpandoObject();
            result.categories = selectionAvailable.For(TableTypes.ContactActivityCategory).Select(tc => new { Description = tc.Name, tc.Id });
            result.activityTypes = selectionAvailable.For(TableTypes.ContactActivityType).Select(tc => new { Description = tc.Name, tc.Id });
            result.HasAttachmentSettings = settings != null && settings.StorageLocations.Any();
            result.CanBrowse = settings != null && settings.EnableBrowseButton;
            result.canBrowseDms = hasDmsSettings && settings?.EnableDms != false
                                                 && _taskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms);
            return result;
        }

        public async Task<ActivityDetails> GetActivity(int activityId)
        {
            var activity = await _dbContext.Set<Activity>().SingleOrDefaultAsync(_ => _.Id == activityId);
            if (activity != null)
            {
                return new ActivityDetails
                {
                    ActivityId = activity.Id,
                    ActivityCategoryId = activity.ActivityCategoryId,
                    ActivityType = activity.ActivityTypeId,
                    ActivityDate = activity.ActivityDate,
                    ActivityCaseId = activity.CaseId,
                    ActivityNameId = activity.ContactNameId,
                    EventId = activity.EventId,
                    EventCycle = activity.Cycle
                };
            }

            return null;
        }

        public async Task<Activity> InsertActivity(int? nameNo, int? caseId, ActivityAttachmentModel details)
        {
            var activity = _dbContext.Set<Activity>().Create();
            activity.Id = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Activity);
            activity.ContactNameId = nameNo;
            activity.CaseId = caseId;
            activity.PriorartId = details.PriorArtId;
            UpdateActivity(activity, details.ActivityDate, details.ActivityCategoryId, details.ActivityType, details.EventId, details.EventCycle);
            activity.Summary = string.Empty;
            var newActivity = _dbContext.Set<Activity>().Add(activity);

            await _dbContext.SaveChangesAsync();

            return newActivity;
        }

        public async Task<Activity> UpdateActivity(int activityId, ActivityAttachmentModel details)
        {
            var activity = await _dbContext.Set<Activity>().Where(_ => _.Id == activityId).SingleAsync();
            var result = UpdateActivity(activity, details.ActivityDate, details.ActivityCategoryId, details.ActivityType, details.EventId, details.EventCycle);

            await _dbContext.SaveChangesAsync();

            return result;
        }

        public async Task<bool> TryDelete(int activityId)
        {
            var activity = await _dbContext.Set<Activity>().Where(_ => _.Id == activityId).SingleAsync();
            if (activity.Attachments.Count == 0)
            {
                DeleteActivity(activity);
                await _dbContext.SaveChangesAsync();

                return true;
            }

            return false;
        }

        Activity UpdateActivity(Activity activity, DateTime? date, int activityCategoryId, int activityType, int? eventId = null, short? cycle = null)
        {
            activity.ActivityDate = date;
            activity.ActivityCategory = _dbContext.Set<TableCode>().Single(_ => _.Id == activityCategoryId);
            activity.ActivityType = _dbContext.Set<TableCode>().Single(_ => _.Id == activityType);
            activity.EventId = eventId;
            activity.Cycle = cycle;

            return activity;
        }

        void DeleteActivity(Activity activity)
        {
            if (activity.Attachments.Count > 0)
            {
                throw new Exception("The activity contains attachments!!");
            }

            _dbContext.Set<Activity>().Remove(activity);
        }
    }

    public class ActivityDetails
    {
        public int? ActivityId { get; set; }
        public int ActivityCategoryId { get; set; }
        public DateTime? ActivityDate { get; set; }
        public int ActivityType { get; set; }
        public short? EventCycle { get; set; }
        public int? EventId { get; set; }
        public string EventDescription { get; set; }
        public int? ActivityCaseId { get; set; }
        public int? ActivityNameId { get; set; }
    }
}