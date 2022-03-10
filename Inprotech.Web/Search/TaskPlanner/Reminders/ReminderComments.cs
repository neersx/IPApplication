using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;

namespace Inprotech.Web.Search.TaskPlanner.Reminders
{
    public interface IReminderComments
    {
        ReminderCommentsPayload Get(string rowKey);
        dynamic Update(ReminderCommentsSaveDetails reminderComments);
        int Count(string rowKey);
    }

    public class ReminderCommentsService : IReminderComments
    {
        readonly IDbContext _dbContext;
        readonly IDisplayFormattedName _displayFormattedName;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IReminderDetailsResolver _reminderDetailsResolver;

        public ReminderCommentsService(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                                       IReminderDetailsResolver reminderDetailsResolver, IDisplayFormattedName displayFormattedName)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _reminderDetailsResolver = reminderDetailsResolver;
            _displayFormattedName = displayFormattedName;
        }

        public ReminderCommentsPayload Get(string rowKey)
        {
            var reminderDetails = _reminderDetailsResolver.Resolve(rowKey);
            var culture = _preferredCultureResolver.Resolve();

            var query = RemindersQuery(reminderDetails).ToList();

            var reminderCommentList = query
                .Select(rc => new ReminderComments
                {
                    DateCreated = rc.DateCreated,
                    StaffNameKey = rc.StaffId,
                    StaffDisplayName = _displayFormattedName.For(rc.StaffId).Result,
                    StaffNameCode = rc.NameCode,
                    Comments = DbFuncs.GetTranslation(rc.Comments, null, rc.MessageTId, culture),
                    IsRecipientComment = rc.StaffId == reminderDetails.EmployeeKey,
                    LogDateTimeStamp = rc.LogDateTimeStamp
                }).ToList();

            return new ReminderCommentsPayload
            {
                Comments = reminderCommentList.SortReminders(),
                ReminderForDisplayName = _displayFormattedName.For(reminderDetails.EmployeeKey).Result
            };
        }

        public dynamic Update(ReminderCommentsSaveDetails reminderComments)
        {
            var reminderDetails = _reminderDetailsResolver.Resolve(reminderComments.TaskPlannerRowKey);

            var reminder = _dbContext.Set<StaffReminder>()
                                     .SingleOrDefault(_ => _.EmployeeReminderId == reminderDetails.Id);
            if(reminder == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            reminder.Comments = reminderComments.Comments;
            _dbContext.SaveChanges();

            return new
            {
                result = "success"
            };
        }

        public int Count(string rowKey)
        {
            var reminderDetails = _reminderDetailsResolver.Resolve(rowKey);
            return RemindersQuery(reminderDetails).Count();
        }

        IQueryable<dynamic> RemindersQuery(ReminderDetails reminderDetails)
        {
            var q1 = from rc in _dbContext.Set<StaffReminder>().Where(_ => _.Comments != null)
                        join n in _dbContext.Set<InprotechKaizen.Model.Names.Name>() on rc.StaffId equals n.Id
                        select new
                        {
                            rc.StaffId,
                            rc.CaseId,
                            rc.Reference,
                            rc.ShortMessage,
                            rc.EventId,
                            rc.Cycle,
                            rc.DateCreated,
                            n.Id,
                            rc.Comments,
                            rc.MessageTId,
                            n.NameCode,
                            StaffNameCode = n.NameCode,
                            rc.LogDateTimeStamp
                        };

            q1 = (reminderDetails.CaseId != null && reminderDetails.CaseId != 0) ? q1.Where(_ => _.CaseId == reminderDetails.CaseId)
                        : q1.Where(_ => _.Reference == reminderDetails.Reference);

            q1 = reminderDetails.EventNo == null && reminderDetails.Cycle == null ? q1.Where(_ => _.ShortMessage == reminderDetails.ReminderMessage)
                        : q1.Where(_ => _.EventId == reminderDetails.EventNo && _.Cycle == reminderDetails.Cycle);
            
            var q2 = from rc in _dbContext.Set<StaffReminder>()
                                              .Where(_ => _.DateCreated == reminderDetails.ReminderDateCreated &&
                                                          _.StaffId == reminderDetails.EmployeeKey
                                                          && _.Comments != null)
                         join n in _dbContext.Set<InprotechKaizen.Model.Names.Name>() on rc.StaffId equals n.Id
                         orderby 2
                         select new
                         {
                             rc.StaffId,
                             rc.CaseId,
                             rc.Reference,
                             rc.ShortMessage,
                             rc.EventId,
                             rc.Cycle,
                             rc.DateCreated,
                             n.Id,
                             rc.Comments,
                             rc.MessageTId,
                             n.NameCode,
                             StaffNameCode = n.NameCode,
                             rc.LogDateTimeStamp
                         };

            return q1.Union(q2);
        }
    }

    public class ReminderComments
    {
        public int StaffNameKey { get; set; }
        public string StaffNameCode { get; set; }
        public string StaffDisplayName { get; set; }
        public string Comments { get; set; }
        public bool IsRecipientComment { get; set; }
        public DateTime? LogDateTimeStamp { get; set; }
        public DateTime DateCreated { get; set; }
    }

    public class ReminderCommentsPayload
    {
        public IEnumerable<ReminderComments> Comments { get; set; }
        public string ReminderForDisplayName { get; set; }
    }

    public class ReminderCommentsSaveDetails
    {
        public string Comments { get; set; }
        public string TaskPlannerRowKey { get; set; }
    }

    public static class ReminderCommentsExtension
    {
        public static IEnumerable<ReminderComments> SortReminders(this List<ReminderComments> comments)
        {
            var recipientReminder = comments.SingleOrDefault(_ => _.IsRecipientComment);
            if(recipientReminder != null)
                comments.Remove(recipientReminder);

            var reminderComments = comments.OrderByDescending(_ => _.LogDateTimeStamp).ToList();
            if(recipientReminder != null) 
                reminderComments.Insert(0, recipientReminder);
            return reminderComments;
        }
    }
}