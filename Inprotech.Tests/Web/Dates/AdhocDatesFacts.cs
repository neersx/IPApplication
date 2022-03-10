using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Dates;
using Inprotech.Web.Search.TaskPlanner;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Dates
{
    public class AdhocDatesFacts
    {
        public class MaintainMethods : FactBase
        {
            [Fact]
            public async Task ThrowNullExceptionWhenMainAdhocDateIsNull()
            {
                var f = new AdhocDateFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.MaintainAdhocDate(Fixture.Integer(), null));
            }

            [Fact]
            public async Task ThrowsExceptionOnMaintainInvalidData()
            {
                var f = new AdhocDateFixture(Db);
                await Assert.ThrowsAsync<InvalidDataException>(() => f.Subject.MaintainAdhocDate(Fixture.Integer(), new AdhocSaveDetails { Reference = Fixture.String(), CaseId = Fixture.Integer(), AlertMessage = Fixture.String(), DeleteOn = Fixture.Date(), DueDate = Fixture.Date(), EmployeeNo = Fixture.Integer(), ImportanceLevel = Fixture.String() }));
            }

            [Fact]
            public async Task ShouldMaintainAdhocDate()
            {
                var f = new AdhocDateFixture(Db);
                var adhocSaveDetails = new AdhocSaveDetails { Reference = Fixture.String(), CaseId = Fixture.Integer(), AlertMessage = Fixture.String(), DeleteOn = Fixture.Date(), DueDate = Fixture.Date(), EmployeeNo = Fixture.Integer(), ImportanceLevel = Fixture.String(), EventNo = Fixture.Integer(), NameNo = Fixture.Integer() };
                new AlertRule(Fixture.Integer(), Fixture.Date())
                {
                    Name = new Name { FirstName = "Cathenna", LastName = "Gill" },
                    StaffName = new Name { FirstName = "George", LastName = "Grey" },
                    CaseId = Fixture.Integer(),
                    DueDate = Fixture.Date().AddDays(2),
                    AlertDate = Fixture.Date().AddDays(2),
                    AlertMessage = "Test Message",
                    Id = 1,
                    DateOccurred = Fixture.Date(),
                    OccurredFlag = 1
                }.In(Db);
                var result = await f.Subject.MaintainAdhocDate(1, adhocSaveDetails);

                Assert.Equal(ReminderActionStatus.Success, result.Status);
            }
        }

        public class CaseEventMethods : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenCaseEventIsNull()
            {
                var f = new AdhocDateFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => await f.Subject.CaseEventDetails(Fixture.Long()));

                Assert.NotNull(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ShouldReturnsEventDetailFromCaseEventWhenCreatedByCriteriaDoesNotExist()
            {
                var f = new AdhocDateFixture(Db);
                var c1 = new Case { Id = -486, Irn = "1234/A", Title = "RONDON and shoe device" }.In(Db);
                var caseEvent1 = new CaseEvent
                {
                    Id = Fixture.Long(),
                    EventDueDate = Fixture.Date(),
                    Case = c1,
                    CreatedByCriteriaKey = null,
                    Event = new Event()
                }.In(Db);

                var result = await f.Subject.CaseEventDetails(caseEvent1.Id);

                Assert.Equal(c1.Id, result.Case.Key);
                Assert.Equal(c1.Irn, result.Case.Code);
                Assert.Equal(c1.Title, result.Case.Value);
            }
        }

        public class GetMethods : FactBase
        {
            [Fact]
            public void ThrowExceptionGet()
            {
                var f = new AdhocDateFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Get(Fixture.Integer()));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException)exception).Response.StatusCode);
            }

            [Fact]
            public void ShouldCallGetForCase()
            {
                var f = new AdhocDateFixture(Db);

                var caseId = Fixture.Integer();
                var dueDate = Fixture.Date().AddDays(5);
                var alertDate = Fixture.Date().AddDays(2);
                var alertId = Fixture.Integer();
                var dateOccured = Fixture.Date();
                new AlertRule(Fixture.Integer(), Fixture.Date())
                {
                    StaffName = new Name { FirstName = "George", LastName = "Grey" },
                    Case = new Case { Irn = "Ref" },
                    CaseId = caseId,
                    DueDate = dueDate,
                    AlertDate = alertDate,
                    Id = alertId,
                    DateOccurred = dateOccured,
                    OccurredFlag = 1
                }.In(Db);
                var updateResult = f.Subject.Get(alertId);

                Assert.Equal("Grey, George", updateResult.AdHocDateFor);
                Assert.Equal(dueDate, updateResult.DueDate);
                Assert.Equal(null, updateResult.Message);
                //Assert.Equal("Ref", updateResult.Reference);
                Assert.Equal(dateOccured, updateResult.DateOccurred);
                Assert.Equal("1", updateResult.ResolveReason);
            }

            [Fact]
            public void ShouldCallGetForName()
            {
                var f = new AdhocDateFixture(Db);
                var dueDate = Fixture.Date().AddDays(5);
                var alertDate = Fixture.Date().AddDays(2);
                var nameId = Fixture.Integer();
                var alertId = Fixture.Integer();
                var dateOccured = Fixture.Date();
                new AlertRule(Fixture.Integer(), Fixture.Date())
                {
                    Name = new Name { FirstName = "Cathenna", LastName = "Gill" },
                    StaffName = new Name { FirstName = "George", LastName = "Grey" },
                    NameId = nameId,
                    DueDate = dueDate,
                    AlertDate = alertDate,
                    AlertMessage = "Test Message",
                    Id = alertId,
                    DateOccurred = dateOccured,
                    OccurredFlag = 1
                }.In(Db);
                var updateResult = f.Subject.Get(alertId);

                Assert.Equal("Grey, George", updateResult.AdHocDateFor);
                Assert.Equal(dueDate, updateResult.DueDate);
                Assert.Equal("Test Message", updateResult.Message);
                //Assert.Equal("Gill, Cathenna", updateResult.Reference);
                Assert.Equal(dateOccured, updateResult.DateOccurred);
                Assert.Equal("1", updateResult.ResolveReason);
            }

            [Fact]
            public void ShouldCallResolveReason()
            {
                var f = new AdhocDateFixture(Db);
                new TableCode(100, (short)TableTypes.AdHocResolveReason, "Event has not occurred but stop policing", "1").In(Db);
                new TableCode(101, (short)TableTypes.AdHocResolveReason, "Approximate date event occurred", "2").In(Db);
                new TableCode(102, (short)TableTypes.AdHocResolveReason, "Event has occurred", "3").In(Db);
                new TableCode(103, (short)TableTypes.AdHocResolveReason, "Event has probably occurred", "4").In(Db);

                var resolveReasons = f.Subject.ResolveReasons();

                Assert.Equal(4, resolveReasons.Count());
            }

            [Fact]
            public async Task ShouldCallViewdata()
            {
                var f = new AdhocDateFixture(Db);
                f.SiteControlReader.Read<int>(SiteControls.DefaultAdhocDateImportance).Returns(0);
                f.SiteControlReader.Read<int>(SiteControls.CriticalReminder).Returns(2);
                new NameBuilder(Db).Build().WithKnownId(2).In(Db);
                f.SecurityContext.User.Returns(new User("internal", false) { Name = new Name(Fixture.Integer()) { NameCode = "Internal" } });

                var result = await f.Subject.ViewData(null);
                var loggedInUser = result.loggedInUser.Code;
                var criticalUser = result.criticalUser.Type;
                var criticalUserId = result.criticalUser.Key;

                Assert.Equal("Internal", loggedInUser);
                Assert.Equal("CriticalUser", criticalUser);
                Assert.Equal(2, criticalUserId);
            }

            [Fact]
            public void ShouldReturnsNamesForCase()
            {
                var f = new AdhocDateFixture(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var name1 = new NameBuilder(Db).Build().In(Db);
                var nameType = new NameType(KnownNameTypes.Signatory, Fixture.String()).In(Db);
                var nameTypeStaff = new NameType(KnownNameTypes.StaffMember, Fixture.String()).In(Db);
                var c = new Case { Id = -486 }.In(Db);
                new CaseName(c, nameType, name, 1).In(Db);
                new CaseName(c, nameTypeStaff, name1, 1).In(Db);
                var result = f.Subject.NameDetails(c.Id).ToArray();

                Assert.Equal("SIG", result[0].Type);
                Assert.Equal("EMP", result[1].Type);
                Assert.Equal(2, result.Length);
            }

            [Fact]
            public void ShouldReturnsRelationshipNamesForCaseAndNametype()
            {
                var f = new AdhocDateFixture(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var name1 = new NameBuilder(Db).Build().In(Db);
                var c = new Case { Id = -486 }.In(Db);
                var nameType = new NameType("D", "Debtor").In(Db);
                new CaseName(c, nameType, name1, 1).In(Db);
                var relationship = new AssociatedNameBuilder(Db)
                {
                    Name = name1,
                    RelatedName = name,
                    Relationship = KnownRelations.Employs
                }.Build().In(Db);
                var result = f.Subject.RelationshipDetails(c.Id, nameType.NameTypeCode, relationship.Relationship).ToArray();

                Assert.Equal(1, result.Length);
                Assert.Equal("Relationship", result[0].Type);
            }
        }

        public class CreateMethods : FactBase
        {
            [Fact]
            public async Task ThrowNullExceptionCreateAdhocDate()
            {
                var f = new AdhocDateFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.CreateAdhocDate(null));
            }

            [Fact]
            public async Task ShouldCreateAdhocDate()
            {
                var f = new AdhocDateFixture(Db);
                var adhocSaveDetails = new AdhocSaveDetails { Reference = Fixture.String(), CaseId = Fixture.Integer(), AlertMessage = Fixture.String(), DeleteOn = Fixture.Date(), DueDate = Fixture.Date(), EmployeeNo = Fixture.Integer(), ImportanceLevel = Fixture.String(), EventNo = Fixture.Integer(), NameNo = Fixture.Integer() };
                var adhocSaveDetailsList = new List<AdhocSaveDetails>();
                adhocSaveDetailsList.Add(adhocSaveDetails);
                var result = await f.Subject.CreateAdhocDate(adhocSaveDetailsList.ToArray());

                Assert.Equal(ReminderActionStatus.Success, result.Status);
            }

            [Fact]
            public async Task ShouldCreateAdhocDateEmailReminder()
            {
                var f = new AdhocDateFixture(Db);
                var adhocSaveDetails = new AdhocSaveDetails
                {
                    Reference = Fixture.String(),
                    CaseId = Fixture.Integer(),
                    AlertMessage = Fixture.String(),
                    DaysLead = 1,
                    DailyFrequency = 1,
                    StopReminderDate = Fixture.Date(),
                    SendElectronically = 1,
                    EmailSubject = "test"
                };
                var adhocSaveDetailsList = new List<AdhocSaveDetails>();
                adhocSaveDetailsList.Add(adhocSaveDetails);
                var result = await f.Subject.CreateAdhocDate(adhocSaveDetailsList.ToArray());
                var sendMail = Db.Set<AlertRule>().FirstOrDefault(_ => _.EmailSubject == "test" && _.SendElectronically == 1);
                Assert.Equal(ReminderActionStatus.Success, result.Status);
                Assert.NotNull(sendMail);
            }

            [Fact]
            public async Task ShouldCreateAdhocDateWithDailyReminder()
            {
                var f = new AdhocDateFixture(Db);
                var adhocSaveDetails = new AdhocSaveDetails { Reference = Fixture.String(), CaseId = Fixture.Integer(), AlertMessage = Fixture.String(), DaysLead = 1, DailyFrequency = 1, StopReminderDate = Fixture.Date() };
                var adhocSaveDetailsList = new List<AdhocSaveDetails>();
                adhocSaveDetailsList.Add(adhocSaveDetails);
                var result = await f.Subject.CreateAdhocDate(adhocSaveDetailsList.ToArray());

                Assert.Equal(ReminderActionStatus.Success, result.Status);
            }

            [Fact]
            public async Task ShouldCreateAdhocDateWithMonthlyReminder()
            {
                var f = new AdhocDateFixture(Db);
                var adhocSaveDetails = new AdhocSaveDetails { Reference = Fixture.String(), CaseId = Fixture.Integer(), AlertMessage = Fixture.String(), MonthsLead = 1, MonthlyFrequency = 1, StopReminderDate = Fixture.Date() };
                var adhocSaveDetailsList = new List<AdhocSaveDetails>();
                adhocSaveDetailsList.Add(adhocSaveDetails);
                var result = await f.Subject.CreateAdhocDate(adhocSaveDetailsList.ToArray());

                Assert.Equal(ReminderActionStatus.Success, result.Status);
            }
        }

        public class FinalizeMethods : FactBase
        {
            [Fact]
            public async Task ShouldFinaliseWithSuccess()
            {
                var f = new AdhocDateFixture(Db);
                var caseId = Fixture.Integer();
                var reference = Fixture.String();
                var dueDate = Fixture.Date().AddDays(5);
                var alertDate = Fixture.Date().AddDays(2);
                var sequenceNo = Fixture.Integer();
                var alertId = Fixture.Integer();
                new AlertRule(Fixture.Integer(), Fixture.Date()) { CaseId = caseId, DueDate = dueDate, Reference = reference, SequenceNo = sequenceNo, AlertDate = alertDate, Id = alertId }.In(Db);
                var finaliseRequest = new FinaliseRequestModel
                {
                    AlertId = alertId,
                    UserCode = 4,
                    DateOccured = Fixture.Date()
                };

                var result = await f.Subject.Finalise(finaliseRequest);

                Assert.Equal(ReminderActionStatus.Success, result.Status);
            }

            [Fact]
            public async Task ThrowNullExceptionBulkFinalise()
            {
                var f = new AdhocDateFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.BulkFinalise(null));
            }

            [Fact]
            public async Task ThrowHttpResponseExceptionBulkFinalise()
            {
                var f = new AdhocDateFixture(Db);
                var taskPlannerRowKeys = new[] { "A^323^99", "C^125^89" };

                f.TaskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(Arg.Any<ReminderActionRequest>()).ReturnsForAnyArgs(taskPlannerRowKeys);

                await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.BulkFinalise(new BulkFinaliseRequestModel()));
            }

            [Fact]
            public async Task ShouldBulkFinaliseWithSuccessStatus()
            {
                var f = new AdhocDateFixture(Db);
                var caseId = Fixture.Integer();
                var reference = Fixture.String();
                var dueDate = Fixture.Date().AddDays(5);
                var alertId = Fixture.Integer();
                var alert1 = new AlertRule(Fixture.Integer(), Fixture.Date()) { CaseId = caseId, DueDate = dueDate, Reference = reference, Id = alertId }.In(Db);
                var bulkFinaliseRequest = new BulkFinaliseRequestModel { DateOccured = Fixture.Date(), UserCode = 2 };
                var taskPlannerRowKeys = new[] { "A^" + alert1.Id + "^123" };

                f.TaskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(Arg.Any<ReminderActionRequest>()).ReturnsForAnyArgs(taskPlannerRowKeys);

                var result = await f.Subject.BulkFinalise(bulkFinaliseRequest);

                Assert.Equal(ReminderActionStatus.Success, result.Status);
            }

            [Fact]
            public async Task ShouldBulkFinaliseWithPartialStatus()
            {
                var f = new AdhocDateFixture(Db);
                var caseId = Fixture.Integer();
                var reference = Fixture.String();
                var dueDate = Fixture.Date().AddDays(5);
                var alertId = Fixture.Integer();
                new AlertRule(Fixture.Integer(), Fixture.Date()) { CaseId = caseId, DueDate = dueDate, Reference = reference, Id = alertId }.In(Db);
                var bulkFinaliseRequest = new BulkFinaliseRequestModel { DateOccured = Fixture.Date(), UserCode = 2 };
                var taskPlannerRowKeys = new[] { "A^" + alertId + "^123", "C^125^89" };

                f.TaskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(Arg.Any<ReminderActionRequest>()).ReturnsForAnyArgs(taskPlannerRowKeys);

                var result = await f.Subject.BulkFinalise(bulkFinaliseRequest);

                Assert.Equal(ReminderActionStatus.PartialCompletion, result.Status);
            }

            [Fact]
            public async Task ShouldNotBulkFinaliseWithUnableToComplete()
            {
                var f = new AdhocDateFixture(Db);
                var bulkFinaliseRequest = new BulkFinaliseRequestModel { DateOccured = Fixture.Date(), UserCode = 2 };
                var taskPlannerRowKeys = new[] { "C^125^89" };

                f.TaskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(Arg.Any<ReminderActionRequest>()).ReturnsForAnyArgs(taskPlannerRowKeys);

                var result = await f.Subject.BulkFinalise(bulkFinaliseRequest);

                Assert.Equal(ReminderActionStatus.UnableToComplete, result.Status);
            }
        }

        public class DeleteMethod : FactBase
        {
            public dynamic SetupReminderDetails()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var staff = new NameBuilder(Db).Build().In(Db);
                var dateCreated = Fixture.Date();
                var sequenceNo = Fixture.Integer();

                var alertRule = new AlertRule(staff.Id, dateCreated)
                {
                    CaseId = @case.Id,
                    SequenceNo = sequenceNo
                }.In(Db);

                var employeeReminder = new StaffReminder(staff.Id, dateCreated)
                {
                    CaseId = @case.Id,
                    SequenceNo = sequenceNo,
                    DateCreated = dateCreated.AddSeconds(3).AddMilliseconds(200),
                    Source = 1
                }.In(Db);

                return new
                {
                    alertId = alertRule.Id,
                    employeeReminderId = employeeReminder.EmployeeReminderId
                };
            }

            [Fact]
            public void ThrowsExceptionWhenAlertNotFound()
            {
                SetupReminderDetails();

                var f = new AdhocDateFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Delete(Fixture.Integer()));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException)exception).Response.StatusCode);
            }

            [Fact]
            public void DeletesAlertWithAssociatedReminder()
            {
                var setup = SetupReminderDetails();
                var alertId = (long)setup.alertId;
                var employeeReminderId = (long)setup.employeeReminderId;

                var f = new AdhocDateFixture(Db);

                var result = f.Subject.Delete(alertId);

                Assert.Equal(ReminderActionStatus.Success, result.Status);
                Assert.Null(Db.Set<AlertRule>().SingleOrDefault(_ => _.Id == alertId));
                Assert.Null(Db.Set<StaffReminder>().SingleOrDefault(_ => _.EmployeeReminderId == employeeReminderId));
            }
        }
    }

    public class AdhocDateFixture : IFixture<AdHocDates>
    {
        public AdhocDateFixture(InMemoryDbContext db = null)
        {
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            PolicingEngine = Substitute.For<IPolicingEngine>();
            TaskPlannerRowSelectionService = Substitute.For<ITaskPlannerRowSelectionService>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            ImportanceLevelResolver = Substitute.For<IImportanceLevelResolver>();
            SecurityContext = Substitute.For<ISecurityContext>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            FunctionSecurityProvider = Substitute.For<IFunctionSecurityProvider>();
            ReminderManager = Substitute.For<IReminderManager>();
            Subject = new AdHocDates(DbContext, PreferredCultureResolver, PolicingEngine, TaskPlannerRowSelectionService, SiteControlReader, ImportanceLevelResolver, SecurityContext, Fixture.Today, TaskSecurityProvider, FunctionSecurityProvider, ReminderManager);
        }

        public IDbContext DbContext { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IPolicingEngine PolicingEngine { get; set; }
        public ITaskPlannerRowSelectionService TaskPlannerRowSelectionService { get; set; }
        public IImportanceLevelResolver ImportanceLevelResolver { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public User CurrentUser { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public IFunctionSecurityProvider FunctionSecurityProvider { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public IReminderManager ReminderManager { get; set; }
        public AdHocDates Subject { get; }
    }
}