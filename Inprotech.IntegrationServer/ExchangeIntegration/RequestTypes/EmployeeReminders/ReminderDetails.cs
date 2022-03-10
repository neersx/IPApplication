using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public interface IReminderDetails
    {
        EmployeeReminders For(int staffId, DateTime dateCreated);
        EmployeeReminders ForUsers(int staffId, int userId, DateTime requestDate);
    }
    public class ReminderDetails : IReminderDetails
    {
        readonly IDbContext _dbContext;
        readonly IReminderFormatter _reminderFormatter;
        readonly IUserFormatter _userFormatter;
        readonly int _criticalLevel;

        public ReminderDetails(IDbContext dbContext, ISiteControlReader siteControls, IReminderFormatter reminderFormatter, IUserFormatter userFormatter)
        {
            _dbContext = dbContext;
            _reminderFormatter = reminderFormatter;
            _userFormatter = userFormatter;

            _criticalLevel = siteControls.Read<int>(SiteControls.CRITICALLEVEL);
        }

        public EmployeeReminders For(int staffId, DateTime dateCreated)
        {
            var reminder = _dbContext.Set<StaffReminder>()
                              .SingleOrDefault(_ => _.StaffId == staffId && _.DateCreated == dateCreated);
            if (reminder == null)
                return null;

            var reminderModel = _reminderFormatter.Create(reminder);
            reminderModel.Comments = _reminderFormatter.GetComments(reminder);
            reminderModel.IsHighPriority = _reminderFormatter.GetPriority(reminder, _criticalLevel);

            var reminderCollection = new List<ExchangeStaffReminder> {reminderModel};

            var userSettings = _userFormatter.Users(staffId);

            return new EmployeeReminders(userSettings, reminderCollection);
        }

        public EmployeeReminders ForUsers(int staffId, int userId, DateTime requestDate)
        {
            var reminders = _dbContext.Set<StaffReminder>()
                                     .Where(_ => _.StaffId == staffId && _.ReminderDate >= requestDate.Date).ToArray();

            var reminderCollection = new List<ExchangeStaffReminder>();

            foreach (var reminder in reminders)
            {
                var v = _reminderFormatter.Create(reminder);
                v.Comments = _reminderFormatter.GetComments(reminder);
                v.IsHighPriority = _reminderFormatter.GetPriority(reminder, _criticalLevel);
                reminderCollection.Add(v);
            }
            
            var userSettings = _userFormatter.Users(staffId).Where(v => v.UserIdentityId == userId);

            return new EmployeeReminders(userSettings, reminderCollection);
        }
    }
}