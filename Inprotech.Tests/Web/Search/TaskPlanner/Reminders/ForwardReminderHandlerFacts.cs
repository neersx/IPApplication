using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search.TaskPlanner;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner.Reminders
{
    public class ForwardReminderHandlerFacts
    {
         public class ProcessMethod : FactBase
        {
            [Fact]
            public void ShouldCallForwardReminders()
            {
                var fixture = new ForwardReminderHandlerFixture(Db);
                var data = fixture.SetupData(Db);
                var toNameId = Fixture.Integer();
                var user = new User(Fixture.UniqueName(), false) { NameId = Fixture.Integer() };
                fixture.SiteControlReader.Read<bool>(SiteControls.AlertSpawningBlocked).Returns(true);
                fixture.SecurityContext.User.Returns(user);
                var req = new ForwardReminderRequest { TaskPlannerRowKeys = new[] { data.AlertRowKey }, ToNameIds = new[] { toNameId } };
                var keyParams = GetRowKeyParams(req.TaskPlannerRowKeys).ToList();
                var reminderIdsToBeProcessed = keyParams.Where(x => x.Type == KnownReminderTypes.AdHocDate || x.EmployeeReminderId.HasValue)
                                                        .Select(x => x.EmployeeReminderId.Value).ToArray();
               
                fixture.Subject.Process(reminderIdsToBeProcessed, req.ToNameIds.ToList(), keyParams);

                var forwardedReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.CaseId == data.AlertReminder.CaseId
                                                                                                   && x.Reference == data.AlertReminder.Reference
                                                                                                   && x.StaffId == toNameId
                                                                                                   && x.SequenceNo == data.AlertReminder.SequenceNo
                                                                                                   && x.Source == 1);
                Assert.Equal(user.NameId, forwardedReminder?.ForwardedFrom);
            }

            [Fact]
            public void ShouldForwardOnlyReminderWhenSiteControlAlertSpawningBlockedIsTrue()
            {
                var fixture = new ForwardReminderHandlerFixture(Db);
                var data = fixture.SetupData(Db);
                fixture.SiteControlReader.Read<bool>(SiteControls.AlertSpawningBlocked).Returns(true);
                var toNameId = Fixture.Integer();
                var user = new User(Fixture.UniqueName(), false) { NameId = Fixture.Integer() };
                fixture.SecurityContext.User.Returns(user);
                var req = new ForwardReminderRequest { TaskPlannerRowKeys = new[] { data.AlertRowKey }, ToNameIds = new[] { toNameId } };
                var keyParams = GetRowKeyParams(req.TaskPlannerRowKeys).ToList();
                var reminderIdsToBeProcessed = keyParams.Where(x => x.Type == KnownReminderTypes.AdHocDate || x.EmployeeReminderId.HasValue)
                                                        .Select(x => x.EmployeeReminderId.Value).ToArray();
               
                fixture.Subject.Process(reminderIdsToBeProcessed, req.ToNameIds.ToList(), keyParams);

                var forwardedReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.CaseId == data.AlertReminder.CaseId
                                                                                                   && x.Reference == data.AlertReminder.Reference
                                                                                                   && x.StaffId == toNameId
                                                                                                   && x.SequenceNo == data.AlertReminder.SequenceNo
                                                                                                   && x.Source == 1);
                Assert.Equal(user.NameId, forwardedReminder?.ForwardedFrom);

                var forwardedAlert = fixture.DbContext.Set<AlertRule>().FirstOrDefault(x => x.CaseId == data.Alert.CaseId
                                                                                                && x.Reference == data.Alert.Reference
                                                                                                && x.StaffId == toNameId
                                                                                                && x.SequenceNo == data.Alert.SequenceNo
                                                                                                && x.Cycle == data.Alert.Cycle);
                Assert.Null(forwardedAlert);
            }
            
            [Fact]
            public void ShouldForwardOnlyReminderWhenSiteControlAlertSpawningBlockedIsFalse()
            {
                var fixture = new ForwardReminderHandlerFixture(Db);
                var data = fixture.SetupData(Db);
                fixture.SiteControlReader.Read<bool>(SiteControls.AlertSpawningBlocked).Returns(false);
                var toNameId = Fixture.Integer();
                var user = new User(Fixture.UniqueName(), false) { NameId = Fixture.Integer() };
                fixture.SecurityContext.User.Returns(user);
                var req = new ForwardReminderRequest { TaskPlannerRowKeys = new[] { data.AlertRowKey }, ToNameIds = new[] { toNameId } };
                var keyParams = GetRowKeyParams(req.TaskPlannerRowKeys).ToList();
                var reminderIdsToBeProcessed = keyParams.Where(x => x.Type == KnownReminderTypes.AdHocDate || x.EmployeeReminderId.HasValue)
                                                        .Select(x => x.EmployeeReminderId.Value).ToArray();
               
                fixture.Subject.Process(reminderIdsToBeProcessed, req.ToNameIds.ToList(), keyParams);
                var forwardedReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.CaseId == data.AlertReminder.CaseId
                                                                                                   && x.Reference == data.AlertReminder.Reference
                                                                                                   && x.StaffId == toNameId
                                                                                                   && x.SequenceNo == data.AlertReminder.SequenceNo
                                                                                                   && x.Source == 1);
                Assert.Equal(user.NameId, forwardedReminder?.ForwardedFrom);

                var forwardedAlert = fixture.DbContext.Set<AlertRule>().FirstOrDefault(x => x.CaseId == data.Alert.CaseId
                                                                                                && x.Reference == data.Alert.Reference
                                                                                                && x.StaffId == toNameId
                                                                                                && x.SequenceNo == data.Alert.SequenceNo
                                                                                                && x.Cycle == data.Alert.Cycle);
                Assert.NotNull(forwardedAlert);
                Assert.Equal(toNameId, forwardedAlert.StaffId);
            }

            List<RowKeyParam> GetRowKeyParams(string[] taskPlannerRowKeys)
            {
                return (from rowKey in taskPlannerRowKeys
                        let keys = rowKey.Split('^')
                        select new RowKeyParam
                        {
                            Key = rowKey,
                            Type = keys[0],
                            AlertId = keys[0] == KnownReminderTypes.AdHocDate ? Convert.ToInt64(keys[1]) : null,
                            CaseEventId = keys[0] == KnownReminderTypes.ReminderOrDueDate && !string.IsNullOrWhiteSpace(keys[1]) ? Convert.ToInt64(keys[1]) : null,
                            EmployeeReminderId = string.IsNullOrWhiteSpace(keys[2]) ? null : Convert.ToInt64(keys[2])
                        }).ToList();
            }
        }
    }

    public class ForwardReminderHandlerFixture : IFixture<IForwardReminderHandler>
    {
        public TaskPlannerData SetupData(InMemoryDbContext db, DateTime? dueDate = null)
        {
            var dateCreated = DateTime.Now.Date;
            var futureDate = dueDate ?? DateTime.Now.Date.AddDays(10);
            var employeeNo = Fixture.Integer();
            var caseId = Fixture.Integer();
            var alertReminder = new StaffReminder(employeeNo, Fixture.Date()) { CaseId = caseId, EventId = Fixture.Integer(), Cycle = Fixture.Short(), DueDate = futureDate, EmployeeReminderId = Fixture.Integer(), IsRead = 0, Source = 1 }.In(db);
            var alert = new AlertRule(employeeNo, dateCreated) { CaseId = caseId, Reference = Fixture.String(), NameId = Fixture.Integer(), SequenceNo = Fixture.Integer(), DueDate = futureDate, Id = Fixture.Integer() }.In(db);

            var cycle2 = Fixture.Short();
            var eventNo2 = Fixture.Integer();
            var caseId2 = Fixture.Integer();
            var dueDateReminder = new StaffReminder(Fixture.Integer(), Fixture.Date()) { CaseId = caseId2, EventId = eventNo2, Cycle = cycle2, DueDate = futureDate, EmployeeReminderId = Fixture.Integer() }.In(db);
            var caseEvent = new CaseEvent(caseId2, eventNo2, cycle2) { ReminderDate = futureDate, Id = Fixture.Integer() }.In(db);
            return new TaskPlannerData
            {
                AlertRowKey = $"A^{alert.Id }^{alertReminder.EmployeeReminderId}",
                AlertReminder = alertReminder,
                Alert = alert,
                DueDateRowKey = $"C^{caseEvent.Id}^{dueDateReminder.EmployeeReminderId}",
                DueDateReminder = dueDateReminder,
                CaseEvent = caseEvent
            };
        }

        public ForwardReminderHandlerFixture(InMemoryDbContext db = null)
        {
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            Now = Substitute.For<Func<DateTime>>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            SecurityContext = Substitute.For<ISecurityContext>();
            Logger = Substitute.For<ILogger<ForwardReminderHandler>>();
            Subject = new ForwardReminderHandler(SiteControlReader, DbContext, Now,SecurityContext, Logger);
        }
        
        public IDbContext DbContext { get; set; }
        public Func<DateTime> Now { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public IForwardReminderHandler Subject { get; set; }
        public ILogger<ForwardReminderHandler> Logger { get; set; }
    }
}
