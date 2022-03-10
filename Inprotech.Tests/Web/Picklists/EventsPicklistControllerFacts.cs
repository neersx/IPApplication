using System.Collections.Generic;
using System.Linq;
using System.Web;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using Action = InprotechKaizen.Model.Cases.Action;
using EntityModel = InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Web.Picklists
{
    public class EventsPicklistControllerFacts : FactBase
    {
        public class Maintenance : FactBase
        {
            [Fact]
            public void AddsNewEvent()
            {
                var e = new EventSaveDetails();
                var f = new EventsPicklistControllerFixture(Db);
                f.Subject.AddOrDuplicate(e);
                f.EventsPicklistMaintenance.Received(1).Save(e, Operation.Add);
            }

            [Fact]
            public void DeletesExistingEvent()
            {
                var e = new EntityModel.Event(Fixture.Integer())
                {
                    Description = Fixture.String(),
                    NumberOfCyclesAllowed = 1
                }.In(Db);
                var f = new EventsPicklistControllerFixture(Db);
                f.Subject.Delete(e.Id);
                f.EventsPicklistMaintenance.Received(1).Delete(e.Id);
            }

            [Fact]
            public void UpdatesExistingEvent()
            {
                var e1 = new EntityModel.Event(Fixture.Integer())
                {
                    Description = Fixture.String(),
                    NumberOfCyclesAllowed = 1
                }.In(Db);
                var e = new EventSaveDetails();
                var f = new EventsPicklistControllerFixture(Db);
                f.Subject.Update(e1.Id, e);
                f.EventsPicklistMaintenance.Received(1).Save(e, Operation.Update);
            }
        }

        public class EventMethod : FactBase
        {
            dynamic Events()
            {
                var e1 = new EntityModel.Event(Fixture.Integer())
                {
                    Code = "OPP",
                    Description = "Official Action 12 month Deadline",
                    ImportanceLevel = "9",
                    InternalImportance = new Importance
                    {
                        Level = "9",
                        Description = Fixture.String("Critical")
                    },
                    NumberOfCyclesAllowed = 2
                }.In(Db);

                var e2 = new EntityModel.Event(Fixture.Integer())
                {
                    Code = "USOA",
                    Description = "FINAL 3 month Office Action-Last Day",
                    ImportanceLevel = "5",
                    InternalImportance = new Importance
                    {
                        Level = "5",
                        Description = "Normal"
                    },
                    NumberOfCyclesAllowed = 9999
                }.In(Db);

                var e3 = new EntityModel.Event(Fixture.Integer())
                {
                    Code = "VQ",
                    Description = Fixture.String("Very Quality Law"),
                    ImportanceLevel = "1",
                    InternalImportance = new Importance
                    {
                        Level = "1",
                        Description = Fixture.String("Critical")
                    },
                    NumberOfCyclesAllowed = 7,
                    CategoryId = 444,
                    Category = new EntityModel.EventCategory(444) {Name = "Q Category"},
                    ClientImportanceLevel = "10",
                    ClientImportance = new Importance
                    {
                        Level = "10",
                        Description = Fixture.String("Serious")
                    },
                    ShouldPoliceImmediate = true,
                    ControllingAction = "VA",
                    Action = new Action("VQAction", null, 1, "VA"),
                    DraftEventId = e2.Id,
                    DraftEvent = e2,
                    IsAccountingEvent = true,
                    Notes = Fixture.String("VQ Notes"),
                    RecalcEventDate = true,
                    SuppressCalculation = false,
                    NoteGroup = new TableCode(Fixture.Integer(), (short) TableTypes.NoteSharingGroup, Fixture.String("NoteGroup")),
                    NotesSharedAcrossCycles = true
                }.In(Db);

                return new
                    {e1, e2, e3};
            }

            [Theory]
            [InlineData(null, false)]
            [InlineData(false, false)]
            [InlineData(true, true)]
            public void ReturnsCorrectNotesSharingProperties(bool? sharedAcrossCycles, bool expected)
            {
                Events();
                var e = new EntityModel.Event(Fixture.Integer())
                {
                    Description = Fixture.String(),
                    NotesSharedAcrossCycles = sharedAcrossCycles
                }.In(Db);
                var f = new EventsPicklistControllerFixture(Db);
                var r = f.Subject.Event(e.Id).Data;
                Assert.Equal(expected, r.NotesSharedAcrossCycles);
            }

            [Theory]
            [InlineData(1, true, true)]
            [InlineData(2, true, false)]
            [InlineData(3, true, false)]
            [InlineData(4, true, false)]
            [InlineData(5, false, false)]
            public void SetsUpdatableCriteriaWhereRequired(int eventId, bool hasUpdatableCriteria, bool isDescriptionUpdatable)
            {
                SetupUpdatableControl();
                var f = new EventsPicklistControllerFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules).Returns(true);
                var r = f.Subject.Event(eventId).Data;
                Assert.Equal(hasUpdatableCriteria, ((EventSaveDetails) r).HasUpdatableCriteria);
                Assert.Equal(isDescriptionUpdatable, ((EventSaveDetails) r).IsDescriptionUpdatable);
            }

            [Theory]
            [InlineData(1, true, true, true)]
            [InlineData(1, false, true, false)]
            [InlineData(1, true, false, true)]
            [InlineData(2, false, true, true)]
            [InlineData(2, true, false, false)]
            [InlineData(4, true, true, true)]
            [InlineData(5, true, true, false)]
            // 1 = protected, 2 = unprotected, 4 = unprotected, no matching originals, 5 = novalidevent
            public void ChecksForProtectedCriteriaRules(int eventId, bool canUpdateProtected, bool canUpdateUnprotected, bool expected)
            {
                SetupUpdatableControl();
                var f = new EventsPicklistControllerFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected).Returns(canUpdateProtected);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules).Returns(canUpdateUnprotected);
                var r = f.Subject.Event(eventId).Data;
                Assert.Equal(expected, ((EventSaveDetails) r).HasUpdatableCriteria);
            }

            void SetupUpdatableControl()
            {
                var protectedCriteria = new Criteria {Id = Fixture.Integer(), UserDefinedRule = 0, PurposeCode = CriteriaPurposeCodes.EventsAndEntries}.In(Db);
                var unprotected = new Criteria {Id = Fixture.Integer(), UserDefinedRule = 1, PurposeCode = CriteriaPurposeCodes.EventsAndEntries}.In(Db);

                new EntityModel.Event(1)
                {
                    Description = "Event1",
                    ImportanceLevel = "5",
                    NumberOfCyclesAllowed = 2,
                    ValidEvents = new List<ValidEvent> {new ValidEvent(protectedCriteria.Id, 1, "Event1") {ImportanceLevel = "3", NumberOfCyclesAllowed = 1}.In(Db)}
                }.In(Db);

                new EntityModel.Event(2)
                {
                    Description = "Event2",
                    ImportanceLevel = "5",
                    NumberOfCyclesAllowed = 2,
                    ValidEvents = new List<ValidEvent> {new ValidEvent(unprotected.Id, 2, Fixture.String("new")) {ImportanceLevel = "5", NumberOfCyclesAllowed = 9999}.In(Db)}
                }.In(Db);

                new EntityModel.Event(3)
                {
                    Description = "Event3",
                    ImportanceLevel = "5",
                    NumberOfCyclesAllowed = 2,
                    ValidEvents = new List<ValidEvent> {new ValidEvent(protectedCriteria.Id, 3, Fixture.String("new")) {ImportanceLevel = "1", NumberOfCyclesAllowed = 2}.In(Db)}
                }.In(Db);

                new EntityModel.Event(4)
                {
                    Description = "Event4",
                    ImportanceLevel = "5",
                    NumberOfCyclesAllowed = 2,
                    ValidEvents = new List<ValidEvent> {new ValidEvent(unprotected.Id, 4, Fixture.String("new")) {ImportanceLevel = "1", NumberOfCyclesAllowed = 9999}.In(Db)}
                }.In(Db);

                new EntityModel.Event(5)
                {
                    Description = "Event5",
                    ImportanceLevel = "9",
                    NumberOfCyclesAllowed = 1
                }.In(Db);
            }

            [Fact]
            public void ReturnsCorrectEventDetails()
            {
                var events = Events();
                var vEvent = (EntityModel.Event) events.e3;
                var f = new EventsPicklistControllerFixture(Db);
                var r = f.Subject.Event(vEvent.Id).Data;

                Assert.Equal(vEvent.ShouldPoliceImmediate, r.AllowPoliceImmediate);
                Assert.Equal(vEvent.Category.Name, r.Category.Name);
                Assert.Equal(vEvent.ClientImportance.Level, r.ClientImportance);
                Assert.Equal(vEvent.Code, r.Code);
                Assert.Equal(vEvent.Action.Name, r.ControllingAction.Value);
                Assert.Equal(vEvent.Description, r.Description);
                Assert.Equal(vEvent.DraftEvent.Description, r.DraftCaseEvent.Value);
                Assert.Equal(vEvent.InternalImportance.Level, r.InternalImportance);
                Assert.Equal(vEvent.IsAccountingEvent, r.IsAccountingEvent);
                Assert.Equal(vEvent.Id, r.Key);
                Assert.Equal(vEvent.NumberOfCyclesAllowed, r.MaxCycles);
                Assert.Equal(vEvent.Notes, r.Notes);
                Assert.Equal(vEvent.RecalcEventDate, r.RecalcEventDate);
                Assert.Equal(vEvent.SuppressCalculation, r.SuppressCalculation);
                Assert.False(r.UnlimitedCycles);
                Assert.Equal(vEvent.NoteGroupId, r.NotesGroup.Key);
                Assert.True(r.NotesSharedAcrossCycles);
            }

            [Fact]
            public void ReturnsNotFoundException()
            {
                Events();
                var f = new EventsPicklistControllerFixture(Db);
                Assert.Throws<HttpException>(() => { f.Subject.Event(0); });
            }

            [Fact]
            public void ReturnsUnlimitedMaxCycle()
            {
                var events = Events();
                var vEvent = (EntityModel.Event) events.e2;
                var f = new EventsPicklistControllerFixture(Db);
                var r = f.Subject.Event(vEvent.Id).Data;

                Assert.Equal(vEvent.Id, r.Key);
                Assert.Equal(9999, r.MaxCycles);
                Assert.True(r.UnlimitedCycles);
            }
        }

        public class SupportDataMethod : FactBase
        {
            void Setup()
            {
                const short eventGroupTableType = (short) TableTypes.EventGroup;
                new Importance("1", Fixture.String()).In(Db);
                new Importance("3", Fixture.String()).In(Db);
                new Importance("4", Fixture.String()).In(Db);
                new Importance("7", Fixture.String()).In(Db);
                new Importance("9", Fixture.String()).In(Db);
                new TableCode(Fixture.Integer(), eventGroupTableType, Fixture.String()).In(Db);
                new TableCode(Fixture.Integer(), eventGroupTableType, Fixture.String()).In(Db);
            }

            [Theory]
            [InlineData(new[] {"1", "3", "4", "7", "9"}, "4")]
            [InlineData(new[] {"9", "5", "7", "6"}, "5")]
            [InlineData(new[] {"1", "2", "3", "4", "5"}, "5")]
            [InlineData(new[] {"1", "2", "ABC", "!@#", "3"}, "3")]
            public void ReturnsCorrectDefaultImportanceLevel(string[] levels, string defaultImportanceLevel)
            {
                foreach (var l in levels)
                    new Importance(l, Fixture.String()).In(Db);
                var f = new EventsPicklistControllerFixture(Db);
                var r = f.Subject.GetSupportData();
                Assert.True(((IEnumerable<dynamic>) r.importanceLevels).ToArray().Length == levels.Length);
                Assert.True(r.defaultImportanceLevel == defaultImportanceLevel);
                Assert.True(r.defaultMaxCycles == 1);
            }

            [Fact]
            public void ReturnsSupportDataAndDefaults()
            {
                Setup();
                var f = new EventsPicklistControllerFixture(Db);
                var r = f.Subject.GetSupportData();
                Assert.True(((IEnumerable<dynamic>) r.importanceLevels).ToArray().Length == 5);
                Assert.True(r.defaultImportanceLevel == "4");
                Assert.True(r.defaultMaxCycles == 1);
            }
        }

        public class FilterDataMethod : FactBase
        {
            [Fact]
            public void ReturnsDistinctImportanceLevelFilter()
            {
                var f = new EventsPicklistControllerFixture(Db);

                f.EventMatcher
                 .MatchingItems(Arg.Any<string>())
                 .Returns(new[]
                 {
                     new MatchedEvent
                     {
                         Importance = "a"
                     },
                     new MatchedEvent
                     {
                         Importance = "b"
                     },
                     new MatchedEvent
                     {
                         Importance = "b"
                     },
                     new MatchedEvent
                     {
                         Importance = null
                     }
                 });

                var r = f.Subject.GetFilterDataForColumn(Fixture.String());
                Assert.Equal(3, r.ToArray().Length);
            }
        }

        public class EventsMethod : FactBase
        {
            [Fact]
            public void CallMatchingItemsCorrectlyWhenDoingPicklistSearch()
            {
                var search = Fixture.String();
                var criteriaId = Fixture.Integer();
                var f = new EventsPicklistControllerFixture(Db);

                f.EventMatcher.MatchingItems(Arg.Any<string>(), Arg.Any<int>())
                 .Returns(new List<MatchedEvent>());

                f.Subject.Events(null, search, criteriaId);
                f.EventMatcher.Received(1).MatchingItems(search);
            }

            [Fact]
            public void CallMatchingItemsCorrectlyWhenNotDoingPicklistSearch()
            {
                var search = Fixture.String();
                var criteriaId = Fixture.Integer();
                var f = new EventsPicklistControllerFixture(Db);

                f.EventMatcher.MatchingItems(Arg.Any<string>(), Arg.Any<int>())
                 .Returns(new List<MatchedEvent>());

                f.Subject.Events(null, search, criteriaId, true);
                f.EventMatcher.Received(1).MatchingItems(search, criteriaId);
            }
        }
    }

    public class EventsPicklistControllerFixture : IFixture<EventsPicklistController>
    {
        public EventsPicklistControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            EventsPicklistMaintenance = Substitute.For<IEventsPicklistMaintenance>();
            EventsPicklistMaintenance.Save(Arg.Any<EventSaveDetails>(), Arg.Any<Operation>()).Returns(new { });
            CommonQueryService = Substitute.For<ICommonQueryService>();
            CommonQueryParameters = CommonQueryParameters.Default;
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            EventMatcher = Substitute.For<IEventMatcher>();

            Subject = new EventsPicklistController(db, PreferredCultureResolver, EventMatcher, EventsPicklistMaintenance, CommonQueryService, TaskSecurityProvider);
            CommonQueryService.Filter(Arg.Any<IEnumerable<Event>>(), Arg.Any<CommonQueryParameters>()).Returns(x => x[0]);
        }

        public IEventMatcher EventMatcher { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IEventsPicklistMaintenance EventsPicklistMaintenance { get; set; }
        public ICommonQueryService CommonQueryService { get; set; }
        public CommonQueryParameters CommonQueryParameters { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public EventsPicklistController Subject { get; }
    }
}