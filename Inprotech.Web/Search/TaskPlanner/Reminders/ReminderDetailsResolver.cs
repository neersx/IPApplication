using System;
using System.Linq;
using System.Net;
using System.Web.Http;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;

namespace Inprotech.Web.Search.TaskPlanner.Reminders
{
    public interface IReminderDetailsResolver
    {
        ReminderDetails Resolve(string rowKey);
    }

    public class ReminderDetailsResolver : IReminderDetailsResolver
    {
        const char RowKeySeparator = '^';
        readonly IDbContext _dbContext;

        public ReminderDetailsResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public ReminderDetails Resolve(string rowKey)
        {
            var items = rowKey.Split(RowKeySeparator);

            if (items[0] == KnownReminderTypes.ReminderOrDueDate) return GetSystemGeneratedReminderDetails(items);
            if (items[0] == KnownReminderTypes.AdHocDate) return GetAdHocReminderDetails(items);

            return null;
        }

        ReminderDetails GetSystemGeneratedReminderDetails(string[] items)
        {
            var caseEventId = !string.IsNullOrWhiteSpace(items[1]) ? Convert.ToInt32(items[1]) : (int?)null;
            var employeeReminderId = !string.IsNullOrWhiteSpace(items[2]) ? Convert.ToInt64(items[2]) : (long?)null;

            var staffReminder = _dbContext.Set<StaffReminder>().SingleOrDefault(_ => _.EmployeeReminderId == employeeReminderId);
            if (staffReminder == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);
            
            var caseEvent = _dbContext.Set<CaseEvent>().SingleOrDefault(_ => _.Id == caseEventId);

            return new ReminderDetails
            {
                Id = staffReminder.EmployeeReminderId,
                CaseId = caseEvent?.CaseId ?? staffReminder.CaseId,
                Cycle = caseEvent?.Cycle ?? staffReminder.Cycle,
                EventNo = caseEvent?.EventNo ?? staffReminder.EventId,
                EmployeeKey = staffReminder.StaffId,
                ReminderMessage = string.IsNullOrEmpty(staffReminder.LongMessage) ? staffReminder.ShortMessage : staffReminder.LongMessage,
                Reference = staffReminder.Reference,
                ReminderDateCreated = staffReminder.DateCreated
            };
        }

        ReminderDetails GetAdHocReminderDetails(string[] items)
        {
            var alertId = !string.IsNullOrWhiteSpace(items[1]) ? Convert.ToInt32(items[1]) : (int?)null;
            var employeeReminderId = !string.IsNullOrWhiteSpace(items[2]) ? Convert.ToInt64(items[2]) : (long?)null;

            var alert = _dbContext.Set<AlertRule>().SingleOrDefault(_ => _.Id == alertId);

            if (alert == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var staffReminder = _dbContext.Set<StaffReminder>()
                                                 .SingleOrDefault(_ => _.EmployeeReminderId == employeeReminderId);

            if (staffReminder == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return new ReminderDetails
            {
                Id = staffReminder.EmployeeReminderId,
                CaseId = staffReminder.CaseId.GetValueOrDefault(),
                Cycle = staffReminder.Cycle,
                EventNo = staffReminder.EventId,
                EmployeeKey = staffReminder.StaffId,
                ReminderMessage = string.IsNullOrEmpty(staffReminder.LongMessage) ? staffReminder.ShortMessage : staffReminder.LongMessage,
                Reference = staffReminder.Reference,
                ReminderDateCreated = staffReminder.DateCreated
            };
        }
    }

    public class ReminderDetails
    {
        public long Id { get; set; }
        public int? CaseId { get; set; }
        public int EmployeeKey { get; set; }
        public int? EventNo { get; set; }
        public short? Cycle { get; set; }
        public string ReminderMessage { get; set; }
        public DateTime ReminderDateCreated { get; set; }
        public string Reference { get; set; }
    }
}
