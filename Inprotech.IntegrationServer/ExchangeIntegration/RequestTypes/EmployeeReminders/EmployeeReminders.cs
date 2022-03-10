using System;
using System.Collections.Generic;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class EmployeeReminders
    {
        public IEnumerable<ExchangeUser> Users { get; set; }

        public IEnumerable<ExchangeStaffReminder> ReminderDetails { get; set; }

        public EmployeeReminders(IEnumerable<ExchangeUser> users, IEnumerable<ExchangeStaffReminder> reminders)
        {
            Users = users ?? throw new ArgumentNullException(nameof(users));
            ReminderDetails = reminders ?? throw new ArgumentNullException(nameof(reminders));
        }
    }

    public class ExchangeUser
    {
        public int UserIdentityId { get; set; }
        public string Culture { get; set; }
        public bool IsUserInitialised { get; set; }
        public string Mailbox { get; set; }
        public bool IsAlertRequired { get; set; }
        public TimeSpan AlertTime { get; set; }
    }

    public class ExchangeStaffReminder
    {
        public int StaffId { get; set; }
        public DateTime DateCreated { get; set; }
        public string Message { get; set; }
        public string CaseReference { get; set; }
        public string AlertReference { get; set; }
        public string Comments { get; set; }
        public DateTime? DueDate { get; set; }
        public DateTime? ReminderDate { get; set; }
        public bool IsHighPriority { get; set; }
    }
}