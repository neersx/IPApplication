using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public interface IReminderFormatter
    {
        ExchangeStaffReminder Create(StaffReminder reminder);
        string GetComments(StaffReminder reminder);
        bool GetPriority(StaffReminder reminder, int? criticalLevel);
    }

    public class ReminderFormatter : IReminderFormatter
    {
        readonly IDbContext _dbContext;
        readonly IValidEventResolver _validEventResolver;

        public ReminderFormatter(IDbContext dbContext, IValidEventResolver validEventResolver)
        {
            _dbContext = dbContext;
            _validEventResolver = validEventResolver;
        }

        public ExchangeStaffReminder Create(StaffReminder reminder)
        {
            return new ExchangeStaffReminder
            {
                CaseReference = reminder.Case?.Irn,
                AlertReference = reminder.Reference,
                DueDate = reminder.DueDate,
                ReminderDate = reminder.ReminderDate,
                Message = !string.IsNullOrWhiteSpace(reminder.LongMessage) ? reminder.LongMessage : reminder.ShortMessage,
                StaffId = reminder.StaffId,
                DateCreated = reminder.DateCreated
            };
        }

        public string GetComments(StaffReminder reminder)
        {
            var generalComments = !string.IsNullOrWhiteSpace(reminder.Comments) ? "Reminder Comments: " + reminder.Comments : string.Empty;

            if (reminder.Case == null)
            {
                return generalComments;
            }

            var comments = string.Join(Environment.NewLine, reminder.Case.Country.CountryAdjective ?? reminder.Case.Country.Name,
                                       reminder.Case.PropertyType,
                                       reminder.Case.CurrentOfficialNumber,
                                       reminder.Case.Title,
                                       generalComments);

            var caseEvent = reminder.Case.CaseEvents.SingleOrDefault(_ => _.CaseId == reminder.CaseId &&
                                                                          _.EventNo == reminder.EventId &&
                                                                          _.Cycle == reminder.Cycle);
            if (caseEvent != null)
            {
                comments += Environment.NewLine + "Comments: " + caseEvent.EffectiveEventText();
            }

            return comments;
        }

        public bool GetPriority(StaffReminder reminder, int? criticalLevel)
        {
            if (reminder.Case != null && reminder.Event != null)
            {
                var validEvent = _validEventResolver.Resolve(reminder.Case, reminder.Event);
                return int.Parse(validEvent?.ImportanceLevel ?? reminder.Event.ImportanceLevel) >= criticalLevel;
            }

            var alertRule = _dbContext.Set<AlertRule>().SingleOrDefault(_ => _.StaffId == reminder.StaffId &&
                                                                             (_.CaseId == reminder.CaseId || _.Reference == reminder.Reference && _.CaseId == null && reminder.CaseId == null) &&
                                                                             _.SequenceNo == reminder.SequenceNo &&
                                                                             reminder.Event == null);
            if (alertRule != null && alertRule.Importance != null)
            {
                return int.Parse(alertRule.Importance) >= criticalLevel;
            }

            return false;
        }
    }
}