using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;

namespace Inprotech.Web.Search.TaskPlanner.Reminders
{
    public interface IForwardReminderHandler
    {
        public Task Process(IList<long> reminderIds, IList<int> nameIds, IList<RowKeyParam> keyParams);
    }
    public class ForwardReminderHandler : IForwardReminderHandler
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;
        readonly Func<DateTime> _now;
        readonly ISecurityContext _securityContext;
        readonly ILogger<ForwardReminderHandler> _logger;

        public ForwardReminderHandler(ISiteControlReader siteControlReader, 
                                      IDbContext dbContext, 
                                      Func<DateTime> now,
                                      ISecurityContext securityContext, ILogger<ForwardReminderHandler> logger)
        {
            _siteControlReader = siteControlReader;
            _dbContext = dbContext;
            _now = now;
            _securityContext = securityContext;
            _logger = logger;
        }

        public async Task Process(IList<long> reminderIds, IList<int> nameIds, IList<RowKeyParam> keyParams)
        {
            if (!keyParams.Any() || !nameIds.Any()) return;

            var alertSpawningBlocked = _siteControlReader.Read<bool>(SiteControls.AlertSpawningBlocked);
            var alertsToBeInserted = new List<AlertRule>();
            if (!alertSpawningBlocked)
            {
                await HandleAlertSpawning(nameIds, keyParams, alertsToBeInserted);
            }

            var remindersToBeForwarded = await (from r in _dbContext.Set<StaffReminder>()
                                                where reminderIds.Contains(r.EmployeeReminderId)
                                                select r).ToArrayAsync();

            var existingReminders = await (from r in _dbContext.Set<StaffReminder>()
                                           where nameIds.Contains(r.StaffId)
                                           select r).ToArrayAsync();

            var remindersToBeInserted = new List<StaffReminder>();
            var reminderIdsToBeRemoved = new List<long>();

            HandleReminders(nameIds, remindersToBeForwarded, existingReminders, remindersToBeInserted, alertSpawningBlocked, reminderIdsToBeRemoved);

            try
            {
                if (reminderIdsToBeRemoved.Any())
                {
                    var remindersToBeDeleted = _dbContext.Set<StaffReminder>().Where(_ => reminderIdsToBeRemoved.Contains(_.EmployeeReminderId));
                    await _dbContext.DeleteAsync(remindersToBeDeleted);
                }

                if (alertsToBeInserted.Any())
                {
                    _dbContext.AddRange(alertsToBeInserted);
                }

                if (remindersToBeInserted.Any())
                {
                    _dbContext.AddRange(remindersToBeInserted);
                }

                await _dbContext.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.Exception(ex);
                throw;
            }
        }
        void HandleReminders(IList<int> nameIds, StaffReminder[] remindersToBeForwarded, StaffReminder[] existingReminders, List<StaffReminder> remindersToBeInserted, bool alertSpawningBlocked, List<long> reminderIdsToBeRemoved)
        {
            var milliseconds = 0;
            foreach (var reminder in remindersToBeForwarded)
            {
                foreach (var toNameId in nameIds)
                {
                    var existingReminder = existingReminders.Union(remindersToBeInserted).SingleOrDefault(x => x.StaffId == toNameId
                                                                                                               && x.CaseId == reminder.CaseId
                                                                                                               && x.Reference == reminder.Reference
                                                                                                               && x.EventId == reminder.EventId
                                                                                                               && x.Cycle == reminder.Cycle
                                                                                                               && x.SequenceNo == reminder.SequenceNo);
                    if (existingReminder != null)
                    {
                        if (alertSpawningBlocked)
                            continue;

                        reminderIdsToBeRemoved.Add(existingReminder.EmployeeReminderId);
                    }

                    milliseconds = milliseconds + 10;
                    var dateCreated = _now().AddMilliseconds(milliseconds);
                    remindersToBeInserted.Add(new StaffReminder(toNameId, dateCreated)
                    {
                        CaseId = reminder.CaseId,
                        Reference = reminder.Reference,
                        EventId = reminder.EventId,
                        Cycle = reminder.Cycle,
                        DueDate = reminder.DueDate,
                        ReminderDate = reminder.ReminderDate,
                        IsRead = 0,
                        Source = reminder.Source,
                        HoldUntilDate = reminder.HoldUntilDate,
                        DateUpdated = reminder.DateUpdated,
                        ShortMessage = reminder.ShortMessage,
                        LongMessage = reminder.LongMessage,
                        SequenceNo = reminder.SequenceNo,
                        NameId = reminder.NameId,
                        AlertNameId = alertSpawningBlocked ? reminder.AlertNameId : toNameId,
                        ForwardedFrom = _securityContext.User.NameId
                    });
                }
            }

        }

        async Task HandleAlertSpawning(IList<int> nameIds, IList<RowKeyParam> keyParams, List<AlertRule> alertsToBeInserted)
        {
            var milliseconds = 0;
            var alertIdsToBeProcessed = keyParams.Where(x => x.Type == KnownReminderTypes.AdHocDate && x.AlertId.HasValue && x.EmployeeReminderId.HasValue)
                                                 .Select(x => x.AlertId.Value).ToArray();

            var existingAlerts = await (from a in _dbContext.Set<AlertRule>()
                                        where alertIdsToBeProcessed.Contains(a.Id)
                                        select a).ToArrayAsync();

            var alertToBeForwarded = await (from a in _dbContext.Set<AlertRule>()
                                            where alertIdsToBeProcessed.Contains(a.Id)
                                            select a).ToArrayAsync();
            foreach (var alert in alertToBeForwarded)
            {
                foreach (var toNameId in nameIds)
                {
                    if (existingAlerts.Union(alertsToBeInserted).Any(x => x.StaffId == toNameId
                                                                          && x.CaseId == alert.CaseId
                                                                          && x.Reference == alert.Reference
                                                                          && x.EventId == alert.EventId
                                                                          && x.Cycle == alert.Cycle
                                                                          && x.SequenceNo == alert.SequenceNo))
                    {
                        continue;
                    }

                    milliseconds = milliseconds + 10;
                    var dateCreated = _now().AddMilliseconds(milliseconds);
                    alertsToBeInserted.Add(new AlertRule(toNameId, dateCreated)
                    {
                        AlertDate = alert.AlertDate,
                        AlertMessage = alert.AlertMessage,
                        CaseId = alert.CaseId,
                        CriticalFlag = alert.CriticalFlag,
                        Cycle = alert.Cycle,
                        DateOccurred = alert.DateOccurred,
                        DailyFrequency = alert.DailyFrequency,
                        DaysLead = alert.DaysLead,
                        DeleteDate = alert.DeleteDate,
                        DueDate = alert.DueDate,
                        EmailSubject = alert.EmailSubject,
                        EmployeeFlag = alert.EmployeeFlag,
                        MonthsLead = alert.MonthsLead,
                        EventId = alert.EventId,
                        Importance = alert.Importance,
                        NameId = alert.NameId,
                        MonthlyFrequency = alert.MonthlyFrequency,
                        NameTypeId = alert.NameTypeId,
                        Reference = alert.Reference,
                        OccurredFlag = alert.OccurredFlag,
                        Relationship = alert.Relationship,
                        SendElectronically = alert.SendElectronically,
                        SequenceNo = alert.SequenceNo,
                        TriggerEventNo = alert.TriggerEventNo,
                        SignatoryFlag = alert.SignatoryFlag,
                        StopReminderDate = alert.StopReminderDate
                    });
                }
            }
        }
    }
}
