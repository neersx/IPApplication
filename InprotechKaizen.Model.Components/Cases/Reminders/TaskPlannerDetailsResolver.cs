using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Cases.Reminders
{
    public interface ITaskPlannerDetailsResolver
    {
        Task<TaskDetails> Resolve(string rowKey);
    }

    public class TaskPlannerDetailsResolver : ITaskPlannerDetailsResolver
    {
        readonly IDbContext _dbContext;
        readonly IDisplayFormattedName _formattedName;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public TaskPlannerDetailsResolver(IPreferredCultureResolver preferredCultureResolver, IDbContext dbContext, IDisplayFormattedName formattedName)
        {
            _preferredCultureResolver = preferredCultureResolver;
            _dbContext = dbContext;
            _formattedName = formattedName;
        }

        public async Task<TaskDetails> Resolve(string rowKey)
        {
            var rowKeys = rowKey.Split('^');
            var type = rowKeys[0];
            TaskDetails details;
            switch (type)
            {
                case TaskPlannerRowType.DueDate:
                    details = await GetDueDateAndReminderTaskDetails(rowKeys);
                    break;
                case TaskPlannerRowType.Alert:
                    details = await GetAlertTaskDetails(rowKeys);
                    break;
                default:
                    return null;
            }

            return details;
        }

        async Task<TaskDetails> GetDueDateAndReminderTaskDetails(string[] rowKeys)
        {
            var culture = _preferredCultureResolver.Resolve();
            var caseEventId = string.IsNullOrWhiteSpace(rowKeys[1]) ? (long?)null : Convert.ToInt64(rowKeys[1]);
            var employeeReminderId = string.IsNullOrWhiteSpace(rowKeys[2]) ? (long?)null : Convert.ToInt64(rowKeys[2]);
            var empNo = _dbContext.Set<StaffReminder>().SingleOrDefault(_ => _.EmployeeReminderId == employeeReminderId)?.StaffId;
            var caseEvents = _dbContext.Set<CaseEvent>().Where(_ => _.Id == caseEventId);
            var caseEvent = caseEvents.First();
            var caseKey = caseEvent.CaseId;
            var eventNo = caseEvent.EventNo;
            var cycle = caseEvent.Cycle;
            var caseEventsByCase = _dbContext.Set<CaseEvent>().Where(x => x.CaseId == caseKey);
            var dueDateCalc = _dbContext.Set<DueDateCalc>().Where(_ => _.EventId == eventNo);
            var caseOffice = _dbContext.Set<Case>().Where(c => c.Id == caseKey).Select(x => new { Office = DbFuncs.GetTranslation(null, x.Office.Name, x.Office.NameTId, culture) }).FirstOrDefault();
            var staffReminders = _dbContext.Set<StaffReminder>().Where(_ => _.CaseId == caseKey && _.Cycle == cycle && _.EventId == eventNo);

            var openAction = _dbContext.Set<OpenAction>().Where(x => x.CaseId == caseKey);
            var events = _dbContext.Set<Event>();
            var eventControl = _dbContext.Set<ValidEvent>();
            var @case = _dbContext.Set<Case>().Where(_ => _.Id == caseKey);
            var interimResults = await (from ce in caseEvents
                                        join er in staffReminders
                                            on new { cid = (int?)ce.CaseId, EventId = (int?)ce.EventNo, cycl = (short?)ce.Cycle }
                                            equals new { cid = er.CaseId, er.EventId, cycl = er.Cycle } into er1
                                        from er in er1.DefaultIfEmpty()
                                        join ev in events
                                            on ce.EventNo equals ev.Id into ev1
                                        from ev in ev1.DefaultIfEmpty()
                                        join ev2 in events
                                            on ce.GoverningEventNo equals ev2.Id into ev22
                                        from ev2 in ev22.DefaultIfEmpty()
                                        join oa in openAction
                                            on new { ce.CaseId, ActionId = ev.ControllingAction }
                                            equals new { oa.CaseId, oa.ActionId } into oa1
                                        from oa in oa1.DefaultIfEmpty()
                                        join ec in eventControl
                                            on new { EventId = ce.EventNo, CriteriaId = oa != null ? oa.CriteriaId : ce.CreatedByCriteriaKey }
                                            equals new { ec.EventId, CriteriaId = (int?)ec.CriteriaId } into ec1
                                        from ec in ec1.DefaultIfEmpty()
                                        join dd in dueDateCalc.GroupBy(_ => new { _.CriteriaId, _.EventId, _.FromEventId })
                                                              .Select(_ => _.OrderByDescending(x => x.Cycle).FirstOrDefault())
                                            on new { cid = ce.CreatedByCriteriaKey, EventId = ce.EventNo, FromEventId = ce.GoverningEventNo }
                                            equals new { cid = (int?)dd.CriteriaId, dd.EventId, dd.FromEventId } into dd1
                                        from dd in dd1.DefaultIfEmpty()
                                        join ce1 in caseEventsByCase
                                            on new { ce.CaseId, EventNo = ce.GoverningEventNo } equals new { ce1.CaseId, EventNo = (int?)ce1.EventNo } into ce11
                                        from ce1 in ce11.DefaultIfEmpty()
                                        join ce2 in caseEventsByCase.GroupBy(_ => new { _.CaseId, _.EventNo })
                                                                    .Select(_ => _.OrderByDescending(x => x.Cycle).FirstOrDefault())
                                            on new { ce.CaseId, EventNo = ce.GoverningEventNo } equals new { ce2.CaseId, EventNo = (int?)ce2.EventNo } into ce21
                                        from ce2 in ce21.DefaultIfEmpty()
                                        join c in @case
                                            on ce.CaseId equals c.Id into c1
                                        from c in c1.DefaultIfEmpty()
                                        where ce.EventDueDate != null && ce.EventNo != -11 && ce.IsOccurredFlag == 0
                                            && dd == null || ((dd.Cycle == null || dd.Cycle <= ce.Cycle && dd.CompareCycle == null)
                                                && ce1 == null || ce1.Cycle == (dd.RelativeCycle == 0 ? ce.Cycle :
                                                    dd.RelativeCycle == 1 ? ce.Cycle - 1 :
                                                    dd.RelativeCycle == 2 ? ce.Cycle + 1 :
                                                    dd.RelativeCycle == 3 ? 1 : ce2.Cycle))
                                            && (er == null || er.Source == 0)
                                        select new TaskDetails
                                        {
                                            CaseKey = caseKey,
                                            Irn = c != null ? c.Irn : null,
                                            EventNo = eventNo,
                                            Type = er != null ? TaskPlannerRowTypeDesc.Reminder : TaskPlannerRowTypeDesc.DueDate,
                                            ReminderDate = er != null ? er.ReminderDate : null,
                                            NextReminderDate = ce.ReminderDate,
                                            DueDate = ce.EventDueDate,
                                            EventDescription = ec != null
                                                ? string.IsNullOrEmpty(ec.Description)
                                                    ? ev != null ? DbFuncs.GetTranslation(null, ev.Description, ev.DescriptionTId, culture) : string.Empty
                                                    : DbFuncs.GetTranslation(null, ec.Description, ec.DescriptionTId, culture)
                                                : string.Empty,
                                            LongReminderMessage = er != null ? DbFuncs.GetTranslation(null, er.LongMessage, er.MessageTId, culture) : string.Empty,
                                            ShortReminderMessage = er != null ? DbFuncs.GetTranslation(null, er.ShortMessage, er.MessageTId, culture) : string.Empty,
                                            ReminderForId = empNo,
                                            GoverningEvent = ce1 != null ? ce1.EventDate ?? ce1.EventDueDate : null,
                                            GoverningEventDesc = ev2 != null
                                                ? DbFuncs.GetTranslation(null, ev2.Description, ev2.DescriptionTId, culture)
                                                : string.Empty,
                                            NameId = er.StaffId != empNo ? er.StaffId : null,
                                            DueDateResponsibilityId = ce.EmployeeNo,
                                            CaseOffice = caseOffice.Office ?? string.Empty,
                                            ForwardedFromNameId = er != null ? er.ForwardedFrom : null,
                                            EmployeeReminderId = er != null ? er.EmployeeReminderId : null,
                                            Cycle = er != null ? er.Cycle : ce.Cycle
                                        }).ToArrayAsync();

            var results = await GetFormattedName(interimResults, employeeReminderId);

            return results;
        }

        async Task<TaskDetails> GetFormattedName(TaskDetails[] results, long? employeeReminderId)
        {
            if (!results.Any()) return null;

            var taskDetail = results.First(x => !employeeReminderId.HasValue || employeeReminderId.Value == x.EmployeeReminderId);
            var nameIds = results.Where(_ => _.NameId.HasValue).Select(_ => _.NameId.Value).Distinct().ToList();
            var reminderForIds = results.Where(_ => _.ReminderForId.HasValue).Select(_ => _.ReminderForId.Value).Distinct().ToList();

            var namesList = new List<int>();
            var dueDateResponsibilityId = taskDetail.DueDateResponsibilityId;
            namesList.AddRange(nameIds);
            var reminderForId = taskDetail.ReminderForId;
            if (reminderForId != null) namesList.Add((int)reminderForId);
            if (taskDetail.DueDateResponsibilityId.HasValue) namesList.Add((int)taskDetail.DueDateResponsibilityId);

            if (!namesList.Any()) return taskDetail;

            var formattedNames = await _formattedName.For(namesList.Distinct().ToArray());
            if (dueDateResponsibilityId.HasValue)
            {
                taskDetail.DueDateResponsibility = formattedNames?.Get((int)dueDateResponsibilityId).Name;
            }

            if (reminderForIds.Any())
            {
                taskDetail.ReminderFor = formattedNames?.Get(reminderForIds.FirstOrDefault()).Name;
            }

            taskDetail.OtherRecipients = string.Join("; ", nameIds.Select(_ => formattedNames?.Get(_).Name));
            taskDetail.ForwardedFrom = taskDetail.ForwardedFromNameId.HasValue ? await _formattedName.For(taskDetail.ForwardedFromNameId.Value) : string.Empty;

            return taskDetail;
        }

        async Task<TaskDetails> GetAlertTaskDetails(string[] rowKeys)
        {
            var employeeReminderId = string.IsNullOrWhiteSpace(rowKeys[2]) ? (long?)null : Convert.ToInt64(rowKeys[2]);
            var alertId = string.IsNullOrWhiteSpace(rowKeys[1]) ? (long?)null : Convert.ToInt64(rowKeys[1]);
            var reminderFor = _dbContext.Set<StaffReminder>().SingleOrDefault(_ => _.EmployeeReminderId == employeeReminderId)?.StaffId;

            var alertRule = _dbContext.Set<AlertRule>().Where(_ => _.Id == alertId);
            var staffReminder = _dbContext.Set<StaffReminder>().Where(_ => _.Source == 1 && _.EventId == null);

            var interimResults = from ar in alertRule
                                 join er in staffReminder
                                     on new { AlertNameId = (int?)ar.StaffId, ar.SequenceNo, ar.CaseId, ar.NameId }
                                     equals new { er.AlertNameId, er.SequenceNo, er.CaseId, er.NameId } into er1
                                 from er in er1.DefaultIfEmpty()
                                 where er == null || ar.Reference == null || ar.Reference == er.Reference && ar.CaseId == null && er.CaseId == null
                                 select new TaskDetails
                                 {
                                     Type = TaskPlannerRowTypeDesc.Alert,
                                     DueDate = ar.DueDate,
                                     ReminderDate = er != null ? er.ReminderDate : null,
                                     NextReminderDate = ar.AlertDate,
                                     LongReminderMessage = ar.AlertMessage,
                                     EventDescription = ar.AlertMessage,
                                     ReminderForId = reminderFor,
                                     NameId = er.StaffId != reminderFor ? er.StaffId : null,
                                     ForwardedFromNameId = er != null ? er.ForwardedFrom : null,
                                     EmployeeReminderId = er != null ? er.EmployeeReminderId : null,
                                     FinalizedDate = ar.DateOccurred,
                                     AdhocResponsibleNameId = ar.StaffId,
                                     Cycle = ar.Cycle
                                 };
            var result = interimResults.ToArray();

            return await GetFormattedRecipients(result, employeeReminderId);
        }

        async Task<TaskDetails> GetFormattedRecipients(TaskDetails[] result, long? employeeReminderId)
        {
            if (!result.Any()) return null;

            var nameIds = result.Where(_ => _.NameId.HasValue).Select(_ => _.NameId.Value).Distinct().ToList();
            var taskDetail = result.First(x => !employeeReminderId.HasValue || employeeReminderId.Value == x.EmployeeReminderId);
            var namesList = new List<int>();
            var reminderId = taskDetail.ReminderForId;
            if (reminderId.HasValue) namesList.Add((int)reminderId);
            if (nameIds.Any()) namesList.AddRange(nameIds);
            taskDetail.AdhocResponsibleName = await _formattedName.For(taskDetail.AdhocResponsibleNameId);
            if (!namesList.Any()) return taskDetail;

            var formattedNames = await _formattedName.For(namesList.Distinct().ToArray());
            if (reminderId.HasValue)
            {
                taskDetail.ReminderFor = formattedNames?.Get((int)reminderId).Name;
            }

            if (nameIds.Any())
            {
                taskDetail.OtherRecipients = string.Join("; ", nameIds.Select(_ => formattedNames?.Get(_).Name));
            }

            taskDetail.ForwardedFrom = taskDetail.ForwardedFromNameId.HasValue ? await _formattedName.For(taskDetail.ForwardedFromNameId.Value) : string.Empty;

            return taskDetail;
        }
    }

    public class TaskDetails
    {
        public int CaseKey { get; set; }

        public string Irn { get; set; }

        public int EventNo { get; set; }
        public string Type { get; set; }
        public string EventDescription { get; set; }
        public DateTime? DueDate { get; set; }
        public DateTime? ReminderDate { get; set; }
        public string ReminderFor { get; set; }
        public DateTime? NextReminderDate { get; set; }
        public DateTime? GoverningEvent { get; set; }
        public string GoverningEventDesc { get; set; }
        public int? NameId { get; set; }
        public int? ReminderForId { get; set; }
        public string Name { get; set; }
        public string CaseOffice { get; set; }
        public string DueDateResponsibility { get; set; }
        public int? DueDateResponsibilityId { get; set; }
        public string OtherRecipients { get; set; }
        public string ForwardedFrom { get; set; }
        public int? ForwardedFromNameId { get; set; }
        public long? EmployeeReminderId { get; set; }
        public DateTime? FinalizedDate { get; set; }
        public string EmailSubject { get; set; }
        public string EmailBody { get; set; }
        public int AdhocResponsibleNameId { get; set; }
        public string AdhocResponsibleName { get; set; }
        public short? Cycle { get; set; }

        [JsonIgnore]
        public string ShortReminderMessage { get; set; }

        [JsonIgnore]
        public string LongReminderMessage { get; set; }

        public string ReminderMessage => LongReminderMessage ?? ShortReminderMessage;
    }

    public static class TaskPlannerRowType
    {
        public const string DueDate = "C";
        public const string Alert = "A";
    }

    public static class TaskPlannerRowTypeDesc
    {
        public const string DueDate = "dueDate";
        public const string Reminder = "reminder";
        public const string Alert = "adHoc";
    }
}