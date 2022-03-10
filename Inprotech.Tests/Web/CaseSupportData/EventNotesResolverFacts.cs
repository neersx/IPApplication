using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class EventNotesResolverFacts : FactBase
    {
        public class NoteTypes : FactBase
        {
            [Fact]
            public void NotesTypesDoesNotHaveDefaultIfPreferenceNotFound()
            {
                var defaultNoteType = 13;
                var f = new EventNotesResolverFixture(Db).WithUser().WithDefaultNoteTypes().WithDefaultSettingValue(defaultNoteType);
                var r = f.Subject.EventNoteTypesWithDefault().ToArray();
                Assert.True(r.Any());
                Assert.True(r.Length == 4);
                Assert.DoesNotContain(r, _ => _.IsDefault);
            }

            [Fact]
            public void NotesTypesForInternal()
            {
                const int defaultNoteType = 3;
                var f = new EventNotesResolverFixture(Db).WithUser().WithDefaultNoteTypes().WithDefaultSettingValue(defaultNoteType);
                var r = f.Subject.EventNoteTypesWithDefault().ToArray();
                Assert.NotEmpty(r);
                Assert.Equal(4, r.Length);
                Assert.Equal(defaultNoteType, r.Single(_ => _.IsDefault).Code);
            }

            [Fact]
            public void NotesTypesNullVisibleToExternalUserBasedOnSiteControl()
            {
                var f = new EventNotesResolverFixture(Db).WithUser(true).WithClientEventTextSiteControl(true);
                var r = f.Subject.EventNoteTypesWithDefault().ToArray();
                Assert.True(r.Length == 1);
                Assert.Contains(r, _ => _.IsDefault);
            }

            [Fact]
            public void NotesTypesPublicVisibleToExternalUser()
            {
                var f = new EventNotesResolverFixture(Db).WithUser(true).WithDefaultNoteTypes();
                var r = f.Subject.EventNoteTypesWithDefault().ToArray();
                Assert.True(r.Any());
                Assert.True(r.Length == 2);
                Assert.DoesNotContain(r, _ => _.IsDefault);
            }
        }

        public class EventAdhocFacts : FactBase
        {
            [Fact]
            public void ShouldReturnsEventDetailFromCaseEventWhenCreatedByCriteriaKeyExist()
            {
                var f = new EventNotesResolverFixture(Db);
                var caseEventId = Fixture.Integer();
                var createdByCriteriaKey = Fixture.Integer();
                var c1 = new Case { Id = -486, Irn = "1234/A", Title = "RONDON and shoe device" }.In(Db);
                var e1 = new EventBuilder().Build().In(Db).WithKnownId(caseEventId);
                new CaseEvent(c1.Id, caseEventId, 1)
                {
                    Id = Fixture.Long(),
                    EventDueDate = Fixture.Date(),
                    Case = c1,
                    CreatedByCriteriaKey = createdByCriteriaKey,
                    Event = e1,
                }.In(Db);
                new ValidEvent(c1.Id, 1, "b")
                {
                    EventId = caseEventId,
                    CriteriaId = createdByCriteriaKey,
                    InstructionType = "A",
                    FlagNumber = 1
                }.In(Db);
                var result = f.Subject.GetDefaultAdhocInfo(c1.Id, caseEventId, 1);

                Assert.Equal(c1.Id, result.Case.Key);
                Assert.Equal(c1.Irn, result.Case.Code);
                Assert.Equal(c1.Title, result.Case.Value);
            }

            [Fact]
            public void ShouldReturnsEventDetailFromCaseEventWhenCreatedByCriteriaKeyDoesNotExist()
            {
                var f = new EventNotesResolverFixture(Db);
                var caseEventId = Fixture.Integer();
                var c1 = new Case { Id = -486, Irn = "1234/A", Title = "RONDON and shoe device" }.In(Db);
                var e1 = new EventBuilder().Build().In(Db).WithKnownId(caseEventId);
                new CaseEvent(c1.Id, caseEventId, 1)
                {
                    Id = Fixture.Long(),
                    EventDueDate = Fixture.Date(),
                    Case = c1,
                    CreatedByCriteriaKey = null,
                    Event = e1,
                }.In(Db);
                new ValidEvent(c1.Id, 1, "b")
                {
                    EventId = caseEventId,
                    InstructionType = "A",
                    FlagNumber = 1
                }.In(Db);
                var result = f.Subject.GetDefaultAdhocInfo(c1.Id, caseEventId, 1);

                Assert.Equal(c1.Id, result.Case.Key);
                Assert.Equal(c1.Irn, result.Case.Code);
                Assert.Equal(c1.Title, result.Case.Value);
            }
        }

        class EventNotesResolverFixture : IFixture<IEventNotesResolver>
        {
            public EventNotesResolverFixture(InMemoryDbContext dbContext)
            {
                DbContext = dbContext;
                SecurityContext = Substitute.For<ISecurityContext>();
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                SiteControl = Substitute.For<ISiteControlReader>();
                ContextInfo = Substitute.For<IContextInfo>();
                EventNotesEmailHelper = Substitute.For<IEventNotesEmailHelper>();
                Bus = Substitute.For<IBus>();

                preferredCultureResolver.Resolve().ReturnsForAnyArgs("en");
                Subject = new EventNotesResolver(DbContext, preferredCultureResolver, SecurityContext, SiteControl, ContextInfo, EventNotesEmailHelper, Bus);
            }

            InMemoryDbContext DbContext { get; }

            ISecurityContext SecurityContext { get; }

            ISiteControlReader SiteControl { get; }

            IEventNotesEmailHelper EventNotesEmailHelper { get; }

            IContextInfo ContextInfo { get; }

            IBus Bus { get; }

            public IEventNotesResolver Subject { get; }

            public EventNotesResolverFixture WithUser(bool isExternal = false)
            {
                var user = new User("user", isExternal).In(DbContext);
                SecurityContext.User.Returns(_ => user);
                return this;
            }

            public EventNotesResolverFixture WithDefaultNoteTypes()
            {
                new EventNoteType(Fixture.String(), true, true) { Id = 1 }.In(DbContext);
                new EventNoteType(Fixture.String(), true, true) { Id = 2 }.In(DbContext);
                new EventNoteType(Fixture.String("Internal"), false, true) { Id = 3 }.In(DbContext);
                return this;
            }

            public EventNotesResolverFixture WithDefaultSettingValue(int defaultEventNoteType)
            {
                new SettingValues
                {
                    SettingId = KnownSettingIds.DefaultEventNoteType,
                    User = DbContext.Set<User>().SingleOrDefault() ?? new User("user", false),
                    IntegerValue = defaultEventNoteType
                }.In(DbContext);
                return this;
            }

            public EventNotesResolverFixture WithClientEventTextSiteControl(bool value)
            {
                SiteControl.Read<bool>(SiteControls.ClientEventText).Returns(value);
                return this;
            }

            public (int caseId, int[] eventIds) Setup()
            {
                int caseId = 1, eventId = 1;
                short cycle = 1;

                var casualPublicNote = new EventNoteType("Casual Public Note", true, true) { Id = 1 }.In(DbContext);
                new EventNoteType("Imprtant Public Note", true, true) { Id = 2 }.In(DbContext);
                var internalNote = new EventNoteType("Internal Note", false, true) { Id = 3 }.In(DbContext);

                var note1 = new EventText(1) { Text = "Note 1" }.In(DbContext);
                new CaseEventText(caseId, eventId, cycle) { EventTextId = note1.Id }.In(DbContext);

                var note2 = new EventText(2, casualPublicNote) { Text = "Note 2", LogDateTimeStamp = DateTime.Now }.In(DbContext);
                new CaseEventText(caseId, eventId, cycle) { EventTextId = note2.Id }.In(DbContext);

                var note3 = new EventText(3, internalNote) { Text = "Note 3" }.In(DbContext);
                new CaseEventText(caseId, eventId, cycle) { EventTextId = note3.Id }.In(DbContext);

                return (caseId, new[] { eventId });
            }
        }

        dynamic SetupEventNote()
        {
            var c1 = new CaseBuilder().Build().In(Db);
            var caseEventId = Fixture.Integer();
            new CaseEvent(c1.Id, 1, 1) { Id = caseEventId }.In(Db);
            var eventNote = new CaseEventNotes
            {
                CaseEventId = caseEventId,
                EventText = "Event text test"
            };
            return eventNote;
        }

        [Fact]
        public void AddEventTextIfNotExists()
        {
            var f = new EventNotesResolverFixture(Db);
            var c1 = new CaseBuilder().Build().In(Db);
            var caseEventId = Fixture.Integer();
            new CaseEvent(c1.Id, 1, 1) { Id = caseEventId }.In(Db);
            var eventNote = new CaseEventNotes
            {
                CaseEventId = caseEventId,
                EventText = "Event text test"
            };
            var r = f.Subject.Update(eventNote);
        }

        [Fact]
        public async Task VerifyUpdateForMultipleNotes()
        {
            var f = new EventNotesResolverFixture(Db);
            var c1 = new CaseBuilder().Build().In(Db);
            var caseEventId = Fixture.Integer();
            new CaseEvent(c1.Id, 1, 1) { Id = caseEventId }.In(Db);

            var notes = new List<CaseEventNotes>
            {
                new()
                {
                    CaseEventId = caseEventId,
                    EventText = Fixture.UniqueName()
                },
                new()
                {
                    CaseEventId = caseEventId,
                    EventText = Fixture.UniqueName()
                }
            };

            var eventTexts = notes.Select(y => y.EventText).ToList();
            await f.Subject.Update(notes);
            var isExist = Db.Set<EventText>().Any(x => eventTexts.Contains(x.Text));
            Assert.True(isExist);
        }

        [Fact]
        public void ReturnsEventNotesAlphabeticalOrder()
        {
            var f = new EventNotesResolverFixture(Db).WithUser();
            var data = f.Setup();

            var r = f.Subject.Resolve(data.caseId, data.eventIds).ToArray();

            Assert.NotEmpty(r);
            Assert.NotNull(r.Single(_ => string.IsNullOrEmpty(_.NoteTypeText)));
            Assert.True(r.Length == 3);
            Assert.True(r[2].NoteTypeText.StartsWith("Internal"));
        }

        [Fact]
        public void ReturnsEventNotesDateTimeStamp()
        {
            var f = new EventNotesResolverFixture(Db).WithUser();
            var data = f.Setup();

            var r = f.Subject.Resolve(data.caseId, data.eventIds).ToArray();

            Assert.NotEmpty(r);
            Assert.NotNull(r.Single(_ => _.LastUpdatedDateTime.HasValue));
            Assert.True(r.Length == 3);
        }

        [Fact]
        public void ReturnsEventNotesForDefaultNoteType()
        {
            const short defaultNoteType = 3;
            var f = new EventNotesResolverFixture(Db).WithUser().WithDefaultSettingValue(defaultNoteType);
            var data = f.Setup();

            var r = f.Subject.Resolve(data.caseId, data.eventIds).ToArray();

            Assert.NotEmpty(r);
            Assert.Single(r, _ => _.IsDefault == true);
            Assert.Equal(defaultNoteType, r.Single(_ => _.IsDefault == true).NoteType);
            Assert.Equal(3, r.Length);
        }

        [Fact]
        public void ReturnsEventNotesForNullDefaultNoteType()
        {
            var f = new EventNotesResolverFixture(Db).WithUser();
            var data = f.Setup();

            var r = f.Subject.Resolve(data.caseId, data.eventIds).ToArray();

            Assert.NotEmpty(r);
            Assert.Single(r, _ => _.IsDefault == true);
            Assert.Null(r.Single(_ => _.IsDefault == true).NoteType);
            Assert.True(r.Length == 3);
        }

        [Fact]
        public void ReturnsPublicNotesAndNotesWithNullTypesIfSiteControlSetForExternalUsers()
        {
            var f = new EventNotesResolverFixture(Db).WithUser(true).WithClientEventTextSiteControl(true);
            var data = f.Setup();

            var r = f.Subject.Resolve(data.caseId, data.eventIds).ToArray();

            Assert.Equal(2, r.Length);
            Assert.Contains(r, _ => !_.NoteType.HasValue);
        }

        [Fact]
        public void ReturnsPublicNotesOnlyIfSiteControlNotSetForExternalUsers()
        {
            var f = new EventNotesResolverFixture(Db).WithUser(true).WithClientEventTextSiteControl(false);
            var data = f.Setup();

            var r = f.Subject.Resolve(data.caseId, data.eventIds).ToArray();

            Assert.Single(r);
            Assert.DoesNotContain(r, _ => !_.NoteType.HasValue);
        }

        [Fact]
        public async Task ThrowExceptionMessageWhenCaseEventDoesNotExist()
        {
            var f = new EventNotesResolverFixture(Db);
            var eventNote = new CaseEventNotes
            {
                CaseEventId = 1
            };
            var exception = await f.Subject.Update(eventNote);

            Assert.Equal("Event Removed", exception.result);
        }

        [Fact]
        public async Task UpdateEventTextForEventTextTypeIfExists()
        {
            var f = new EventNotesResolverFixture(Db);
            var c1 = new CaseBuilder().Build().In(Db);

            var caseEventId = Fixture.Integer();
            new CaseEvent(c1.Id, 1, 1) { Id = caseEventId }.In(Db);
            var eventNoteType = new EventNoteType { Id = Fixture.Short(), Description = Fixture.String() }.In(Db);
            var eventNote = new CaseEventNotes
            {
                CaseEventId = caseEventId,
                EventNoteType = eventNoteType.Id,
                EventText = "Event text test"
            };

            var updateResult = await f.Subject.Update(eventNote);
            Assert.Equal("success", updateResult.result);
        }

        [Fact]
        public async Task UpdateEventTextIfExists()
        {
            var f = new EventNotesResolverFixture(Db);
            var eventNote = SetupEventNote();
            var updateResult = await f.Subject.Update(eventNote);
            Assert.Equal("success", updateResult.result);
        }

        [Fact]
        public void ShouldReturnEventNote()
        {
            var f = new EventNotesResolverFixture(Db);
            new TableCode(100, (int)ProtectedTableTypes.EventNotes, "Event Notes").In(Db);
            var r = f.Subject.GetPredefinedNotes().ToArray();

            Assert.Equal(1, r.Length);
            Assert.Equal("Event Notes", r[0].Name);
        }

        [Fact]
        public void ShouldNotReturnEventNote()
        {
            var f = new EventNotesResolverFixture(Db);
            var r = f.Subject.GetPredefinedNotes().ToArray();

            Assert.Equal(0, r.Length);
        }
    }
}