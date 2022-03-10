using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search.TaskPlanner;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Reminders;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner.Reminders
{
    public class ReminderManagerFacts
    {
        public class DismissMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallDismissPassingAdHocDate()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                fixture.SiteControlReader.Read<int>(SiteControls.ReminderDeleteButton).Returns(0);
                fixture.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<IEnumerable<int>>()).Returns(new[] { data.AlertReminder.StaffId });
                var result = await fixture.Subject.Dismiss(new DismissReminderRequest { RequestType = ReminderRequestType.BulkAction, TaskPlannerRowKeys = new[] { data.AlertRowKey } });

                Assert.Equal(0, result.UnprocessedRowKeys.Count);
                Assert.Equal(ReminderActionStatus.Success, result.Status);
                Assert.Equal("taskPlannerBulkActionMenu.dismissedMessage", result.Message);
                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.EmployeeReminderId == data.AlertReminder.EmployeeReminderId);
                Assert.Null(staffReminder);
            }

            [Fact]
            public async Task ShouldNotDismissAdHocDateIfDueDateFutureDate()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                fixture.SiteControlReader.Read<int>(SiteControls.ReminderDeleteButton).Returns(2);
                fixture.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<IEnumerable<int>>()).Returns(new[] { data.AlertReminder.StaffId });
                var result = await fixture.Subject.Dismiss(new DismissReminderRequest { RequestType = ReminderRequestType.InlineTask, TaskPlannerRowKeys = new[] { data.AlertRowKey } });
                Assert.Equal(1, result.UnprocessedRowKeys.Count);
                Assert.Equal(ReminderActionStatus.UnableToComplete, result.Status);
                Assert.Equal("modal.unableToComplete", result.MessageTitle);
                Assert.Equal("taskPlannerTaskMenu.couldNotBeDismissedMessage", result.Message);
                var alert = fixture.DbContext.Set<AlertRule>().FirstOrDefault(x => x.Id == data.Alert.Id);
                Assert.NotNull(alert);
                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.EmployeeReminderId == data.AlertReminder.EmployeeReminderId);
                Assert.NotNull(staffReminder);
            }

            [Fact]
            public async Task ShouldCallDismissPassingReminder()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                fixture.SiteControlReader.Read<int>(SiteControls.ReminderDeleteButton).Returns(0);
                fixture.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<IEnumerable<int>>()).Returns(new[] { data.AlertReminder.StaffId });
                var result = await fixture.Subject.Dismiss(new DismissReminderRequest { RequestType = ReminderRequestType.InlineTask, TaskPlannerRowKeys = new[] { data.AlertRowKey } });

                Assert.Equal(0, result.UnprocessedRowKeys.Count);
                Assert.Equal(ReminderActionStatus.Success, result.Status);
                Assert.Equal("taskPlannerTaskMenu.dismissedMessage", result.Message);
                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.EmployeeReminderId == data.AlertReminder.EmployeeReminderId);
                Assert.Null(staffReminder);
            }

            [Fact]
            public async Task ShouldNotDismissIfDueDateFutureDate()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                fixture.SiteControlReader.Read<int>(SiteControls.ReminderDeleteButton).Returns(2);
                fixture.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<IEnumerable<int>>()).Returns(new[] { data.DueDateReminder.StaffId });
                var result = await fixture.Subject.Dismiss(new DismissReminderRequest { RequestType = ReminderRequestType.InlineTask, TaskPlannerRowKeys = new[] { data.DueDateRowKey } });
                Assert.Equal(1, result.UnprocessedRowKeys.Count);
                Assert.Equal(ReminderActionStatus.UnableToComplete, result.Status);
                Assert.Equal("taskPlannerTaskMenu.couldNotBeDismissedMessage", result.Message);
                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.EmployeeReminderId == data.DueDateReminder.EmployeeReminderId);
                Assert.NotNull(staffReminder);
            }

            [Fact]
            public async Task ShouldThrowArgumentNullException()
            {
                var fixture = new ReminderManagerFixture();
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.Dismiss(null); });
            }
        }

        public class DeferMethod : FactBase
        {
            [Fact]
            public async Task ShouldNotDeferredReminder()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db, DateTime.Today.AddDays(15));
                fixture.SiteControlReader.Read<int>(SiteControls.HOLDEXCLUDEDAYS).Returns(5);
                var req = new DeferReminderRequest { TaskPlannerRowKeys = new[] { data.AlertRowKey }, HoldUntilDate = DateTime.Today.AddDays(12) };
                var result = await fixture.Subject.Defer(req);

                Assert.Equal(ReminderActionStatus.UnableToComplete, result.Status);
                Assert.Equal(req.TaskPlannerRowKeys.Length, result.UnprocessedRowKeys.Count);
            }

            [Fact]
            public async Task ShouldNotDeferredEmployeeReminder()
            {
                var fixture = new ReminderManagerFixture(Db);
                var caseId = Fixture.Integer();
                var eventNo = Fixture.Integer();
                var cycle = Fixture.Short();
                var employeeNo = Fixture.Integer();
                var dueDate = DateTime.Today.AddDays(15);
                var enteredDate = DateTime.Today.AddDays(14);
                var reminderId = Fixture.Integer();
                fixture.SiteControlReader.Read<int>(SiteControls.HOLDEXCLUDEDAYS).Returns(5);
                new StaffReminder(employeeNo, Fixture.Date()) { CaseId = caseId, EventId = eventNo, Cycle = cycle, DueDate = dueDate, EmployeeReminderId = reminderId }.In(Db);
                new CaseEvent(caseId, eventNo, cycle) { ReminderDate = enteredDate }.In(Db);
                var req = new DeferReminderRequest { TaskPlannerRowKeys = new[] { $"C^{caseId}^{eventNo}^{cycle}^{employeeNo}^{reminderId}" }, HoldUntilDate = enteredDate };
                var result = await fixture.Subject.Defer(req);
                Assert.Equal(ReminderActionStatus.UnableToComplete, result.Status);
                Assert.Equal(req.TaskPlannerRowKeys.Length, result.UnprocessedRowKeys.Count);
                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.CaseId == caseId && x.EventId == eventNo && x.Cycle == cycle);
                Assert.Null(staffReminder?.HoldUntilDate);
            }

            [Fact]
            public async Task ShouldThrowArgumentNullException()
            {
                var fixture = new ReminderManagerFixture();
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.Defer(null); });
            }
        }

        public class MarkAsReadOrUnreadMethod : FactBase
        {
            [Fact]
            public async Task ShouldMarkAsRead()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                fixture.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<IEnumerable<int>>()).Returns(new[] { data.AlertReminder.StaffId });
                var req = new ReminderReadUnReadRequest { TaskPlannerRowKeys = new[] { data.AlertRowKey }, IsRead = true };
                var result = await fixture.Subject.MarkAsReadOrUnread(req);

                Assert.Equal(1, result);

                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.EmployeeReminderId == data.AlertReminder.EmployeeReminderId);
                Assert.Equal(1, staffReminder?.IsRead);
            }

            [Fact]
            public async Task ShouldNotMarkAsReadWithoutFunctionSecurity()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                fixture.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<IEnumerable<int>>()).Returns(new int[0]);
                var req = new ReminderReadUnReadRequest { TaskPlannerRowKeys = new[] { data.AlertRowKey }, IsRead = true };
                var result = await fixture.Subject.MarkAsReadOrUnread(req);

                Assert.Equal(0, result);

                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.EmployeeReminderId == data.AlertReminder.EmployeeReminderId);

                Assert.Equal(0, staffReminder?.IsRead);
            }

            [Fact]
            public async Task ShouldThrowArgumentNullException()
            {
                var fixture = new ReminderManagerFixture();
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.MarkAsReadOrUnread(null); });
            }
        }

        public class ChangeDueDateResponsibilityMethod : FactBase
        {
            [Fact]
            public async Task ShouldChangeDueDateResponsibility()
            {
                var fixture = new ReminderManagerFixture(Db);

                var toNameId = Fixture.Integer();
                var data = fixture.SetupData(Db);
                var req = new DueDateResponsibilityRequest { TaskPlannerRowKeys = new[] { data.DueDateRowKey }, ToNameId = toNameId };
                var result = await fixture.Subject.ChangeDueDateResponsibility(req);

                Assert.Equal(ReminderActionStatus.Success, result.Status);
                var caseEvent = fixture.DbContext.Set<CaseEvent>().First(x => x.Id == data.CaseEvent.Id);
                Assert.Equal(toNameId, caseEvent.EmployeeNo);
                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.EmployeeReminderId == data.DueDateReminder.EmployeeReminderId);
                Assert.Equal(1, staffReminder?.IsRead);
            }

            [Fact]
            public async Task ShouldNotChangeDueDateResponsibilityForAdHoc()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                var req = new DueDateResponsibilityRequest { TaskPlannerRowKeys = new[] { data.AlertRowKey }, ToNameId = Fixture.Integer() };
                var result = await fixture.Subject.ChangeDueDateResponsibility(req);

                Assert.Equal(ReminderActionStatus.UnableToComplete, result.Status);
            }

            [Fact]
            public async Task ShouldThrowArgumentNullException()
            {
                var fixture = new ReminderManagerFixture();
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.ChangeDueDateResponsibility(null); });
            }
        }

        public class GetDueDateResponsibilityMethod : FactBase
        {
            [Fact]
            public async Task ShouldGetResponsibilityName()
            {
                var fixture = new ReminderManagerFixture(Db);
                var name = new InprotechKaizen.Model.Names.Name(Fixture.Integer()) { NameCode = Fixture.String(), FirstName = Fixture.String(), LastName = Fixture.String() }.In(Db);
                var data = fixture.SetupData(Db, null, name.Id);
                var result = await fixture.Subject.GetDueDateResponsibility(data.DueDateRowKey);
                Assert.NotNull(result);
                Assert.Equal(data.CaseEvent.EmployeeNo, result.Key);
            }

            [Fact]
            public async Task ShouldNotGetResponsibilityName()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                var name = await fixture.Subject.GetDueDateResponsibility(data.DueDateRowKey);
                Assert.Null(name);
            }

            [Fact]
            public async Task ShouldThrowArgumentNullException()
            {
                var fixture = new ReminderManagerFixture();
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GetDueDateResponsibility(null); });
            }
        }

        public class ForwardReminderMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallForwardReminders()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                var toNameId = Fixture.Integer();
                var user = new User(Fixture.UniqueName(), false) { NameId = Fixture.Integer() };
                fixture.SecurityContext.User.Returns(user);
                var req = new ForwardReminderRequest { TaskPlannerRowKeys = new[] { data.AlertRowKey }, ToNameIds = new[] { toNameId } };
                var result = await fixture.Subject.ForwardReminders(req);

                Assert.Equal(ReminderActionStatus.Success, result.Status);
                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.EmployeeReminderId == data.AlertReminder.EmployeeReminderId);
                Assert.Equal(1, staffReminder?.IsRead);
            }

            [Fact]
            public async Task ShouldNotForwardReminders()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                var toNameId = Fixture.Integer();
                var req = new ForwardReminderRequest { TaskPlannerRowKeys = new[] { "C^" + data.CaseEvent.Id + "^" }, ToNameIds = new[] { toNameId } };
                var result = await fixture.Subject.ForwardReminders(req);
                Assert.Equal(ReminderActionStatus.UnableToComplete, result.Status);
            }

            [Fact]
            public async Task ShouldThrowArgumentNullException()
            {
                var fixture = new ReminderManagerFixture();
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.ForwardReminders(null); });
            }
        }

        public class GetEmailContentMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallGetEmailContent()
            {
                var fixture = new ReminderManagerFixture(Db);
                var data = fixture.SetupData(Db);
                var bodyText = Fixture.String();
                var subjectText = Fixture.String();
                fixture.SiteControlReader.Read<string>(SiteControls.EmailTaskPlannerSubject).Returns("EMAIL_SUBJECT");
                fixture.SiteControlReader.Read<string>(SiteControls.EmailTaskPlannerBody).Returns("EMAIL_BODY");

                fixture.TaskPlannerEmailResolver.Resolve(data.AlertRowKey, "EMAIL_BODY").Returns(bodyText);
                fixture.TaskPlannerEmailResolver.Resolve(data.AlertRowKey, "EMAIL_SUBJECT").Returns(subjectText);
                var result = (await fixture.Subject.GetEmailContent(new[] { data.AlertRowKey })).First();

                Assert.Equal(bodyText, result.Body);
                Assert.Equal(subjectText, result.Subject);
                var staffReminder = fixture.DbContext.Set<StaffReminder>().FirstOrDefault(x => x.EmployeeReminderId == data.AlertReminder.EmployeeReminderId);
                Assert.Equal(1, staffReminder?.IsRead);
            }

            [Fact]
            public async Task ShouldThrowArgumentNullException()
            {
                var fixture = new ReminderManagerFixture();
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GetEmailContent(null); });
            }
        }
    }

    public class ReminderManagerFixture : IFixture<IReminderManager>
    {
        public ReminderManagerFixture(InMemoryDbContext db = null)
        {
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            Now = Substitute.For<Func<DateTime>>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            SecurityContext = Substitute.For<ISecurityContext>();
            FunctionSecurityProvider = Substitute.For<IFunctionSecurityProvider>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            TaskPlannerEmailResolver = Substitute.For<ITaskPlannerEmailResolver>();
            ForwardReminderHandler = Substitute.For<IForwardReminderHandler>();
            Subject = new ReminderManager(DbContext, Now, SiteControlReader, SecurityContext, FunctionSecurityProvider, TaskPlannerEmailResolver, ForwardReminderHandler);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public IDbContext DbContext { get; set; }
        public Func<DateTime> Now { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public IFunctionSecurityProvider FunctionSecurityProvider { get; set; }
        public ITaskPlannerEmailResolver TaskPlannerEmailResolver { get; set; }
        public IForwardReminderHandler ForwardReminderHandler { get; set; }
        public IReminderManager Subject { get; }

        public TaskPlannerData SetupData(InMemoryDbContext db, DateTime? dueDate = null, int? responsibilityNameNo = null)
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

            var caseEvent = new CaseEvent(caseId2, eventNo2, cycle2) { ReminderDate = futureDate, Id = Fixture.Integer(), EmployeeNo = responsibilityNameNo }.In(db);
            return new TaskPlannerData
            {
                AlertRowKey = $"A^{alert.Id}^{alertReminder.EmployeeReminderId}",
                AlertReminder = alertReminder,
                Alert = alert,
                DueDateRowKey = $"C^{caseEvent.Id}^{dueDateReminder.EmployeeReminderId}",
                DueDateReminder = dueDateReminder,
                CaseEvent = caseEvent
            };
        }
    }

    public class TaskPlannerData
    {
        public string AlertRowKey { get; set; }
        public StaffReminder AlertReminder { get; set; }
        public AlertRule Alert { get; set; }
        public string DueDateRowKey { get; set; }
        public StaffReminder DueDateReminder { get; set; }
        public CaseEvent CaseEvent { get; set; }
    }
}