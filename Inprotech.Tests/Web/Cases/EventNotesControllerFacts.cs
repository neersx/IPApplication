using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Policy;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class EventNotesControllerFacts : FactBase
    {
        [Fact]
        public void ShouldReturnFalseWhenPredefinedNotesDoesNotExist()
        {
            var fixture = new EventNotesControllerFixture();
            fixture.EventNotesResolver.GetPredefinedNotes().Returns(new List<TableCode>().AsQueryable());
            var r = fixture.Subject.IsPredefinedNotesExists();

            Assert.Equal(false, r);
        }

        [Fact]
        public void ShouldReturnTrueWhenPredefinedNotesExists()
        {
            var fixture = new EventNotesControllerFixture();
            var t1 = new TableCode(100, (int)ProtectedTableTypes.EventNotes, "Event Notes").In(Db);
            var tableCode = new List<TableCode> { t1 }.AsQueryable();
            fixture.EventNotesResolver.GetPredefinedNotes().Returns(tableCode);
            var r = fixture.Subject.IsPredefinedNotesExists();

            Assert.Equal(true, r);
        }

        [Fact]
        public async Task ShouldReturnSuccessWhenMaintainEventNotes()
        {
            var fixture = new EventNotesControllerFixture();
            var updateResult = new
            {
                Result = "success"
            };
            fixture.EventNotesResolver.Update(Arg.Any<CaseEventNotes>()).Returns(updateResult);

            var result = await fixture.Subject.MaintainEventNotes(Arg.Any<CaseEventNotes>());
            Assert.Equal(updateResult, result);
        }

        [Fact]
        public void ViewEventNoteTypesForInternalUser()
        {
            var fixture = new EventNotesControllerFixture();
            var noteTypesResult = new List<NotesTypeData>();
            fixture.EventNotesResolver.EventNoteTypesWithDefault().Returns(noteTypesResult);

            var r = fixture.Subject.GetEventNoteTypes();

            Assert.Equal(noteTypesResult, r);
        }

        [Fact]
        public void ViewGetEventNotesDetailsNotForAdHocDate()
        {
            var employeeReminderId = Fixture.Integer();
            var caseEventId = Fixture.Integer();
            new StaffReminder(Fixture.Integer(), Fixture.Date()) { CaseId = Fixture.Integer(), EventId = Fixture.Integer(), Cycle = Fixture.Short(), DueDate = Fixture.FutureDate(), EmployeeReminderId = employeeReminderId }.In(Db);
            new CaseEvent(Fixture.Integer(), Fixture.Integer(), Fixture.Short()) { Id = caseEventId, ReminderDate = Fixture.FutureDate() }.In(Db);
            var rowKey = $"C^{caseEventId}^{employeeReminderId}";
            var fixture = new EventNotesControllerFixture(Db);
            var caseEventNotesResult = new List<CaseEventNotesData>();
            fixture.EventNotesResolver.Resolve(111, new[] { -123 }).Returns(caseEventNotesResult as IQueryable<CaseEventNotesData>);

            var r = fixture.Subject.GetEventNotesDetails(rowKey);

            Assert.Equal(caseEventNotesResult, r);
        }

        [Fact]
        public void VerifyGetEventNotesDetailsForProviderInstructions()
        {
            var caseKey = Fixture.Integer();
            var eventNo = Fixture.Integer();
            var cycle = Fixture.Short();
            var rowKey = $"I^{caseKey}^{eventNo}^{cycle}";
            var fixture = new EventNotesControllerFixture(Db);
            var caseEventNotesResult = new List<CaseEventNotesData> { new() { Cycle = cycle, EventId = eventNo, EventText = Fixture.String(), NoteTypeText = Fixture.String() } };
            fixture.EventNotesResolver.Resolve(Arg.Any<int>(), Arg.Any<int[]>()).Returns(caseEventNotesResult.AsQueryable());
            var r = fixture.Subject.GetEventNotesDetails(rowKey);
            Assert.Equal(caseEventNotesResult, r);
        }
    }

    public class EventAdhocFacts : FactBase
    {
        [Fact]
        public void ShouldReturnsEventDetailFromCaseEventWhenCreatedByCriteriaKeyExist()
        {
            var f = new EventNotesControllerFixture(Db);
            var caseEventId = Fixture.Long();
            var staffReminderId = Fixture.Integer();
            f.SiteControlReader.Read<int>(SiteControls.DefaultAdhocDateImportance).Returns(0);
            var c1 = new Case { Id = -486, Irn = "1234/A", Title = "RONDON and shoe device" }.In(Db);
            new CaseEvent
            {
                Id = caseEventId,
                EventDueDate = Fixture.Date(),
                Case = c1,
                CreatedByCriteriaKey = Fixture.Integer(),
                Event = new Event()
            }.In(Db);
            var rowKey = $"C^{caseEventId}^{staffReminderId}";
            var result = f.Subject.GetDefaultAdHocInfo(rowKey);

            Assert.Equal(c1.Id, result.Case.Key);
            Assert.Equal(c1.Irn, result.Case.Code);
            Assert.Equal(c1.Title, result.Case.Value);
        }
    }

    public class EventNotesControllerFixture : IFixture<EventNotesController>
    {
        public EventNotesControllerFixture(InMemoryDbContext db = null)
        {
            SiteControlReader = Substitute.For<ISiteControlReader>();
            EventNotesResolver = Substitute.For<IEventNotesResolver>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            SiteDateFormat = Substitute.For<ISiteDateFormat>();
            SecurityContext = Substitute.For<ISecurityContext>();
            Now = Substitute.For<Func<DateTime>>();
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            Subject = new EventNotesController(EventNotesResolver, SiteControlReader, PreferredCultureResolver, SiteDateFormat, SecurityContext, Now, DbContext);
        }

        public ISiteControlReader SiteControlReader { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public ISiteDateFormat SiteDateFormat { get; }
        public ISecurityContext SecurityContext { get; }
        public Func<DateTime> Now { get; }
        public IEventNotesResolver EventNotesResolver { get; set; }
        public IDbContext DbContext { get; set; }
        public EventNotesController Subject { get; }
    }
}