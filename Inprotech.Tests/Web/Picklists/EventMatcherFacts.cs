using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.Translations;
using NSubstitute;
using Xunit;
using Action = InprotechKaizen.Model.Cases.Action;
using EntityModel = InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Web.Picklists
{
    public class EventMatcherFacts
    {
        public class EventsMethod : FactBase
        {
            public IEnumerable<Event> GetEventItems()
            {
                return Db.Set<EntityModel.Event>()
                         .Select(_ => new Event
                         {
                             Key = _.Id,
                             Code = _.Code,
                             Value = _.Description,
                             MaxCycles = _.NumberOfCyclesAllowed,
                             Importance = _.InternalImportance != null ? _.InternalImportance.Description : null,
                             ImportanceLevel = _.InternalImportance != null ? _.InternalImportance.Level : null
                         });
            }

            [Fact]
            public void ChecksLookupCultureOnce()
            {
                var f = new EventMatcherFixture(Db);
                f.Subject.MatchingItems(Fixture.String());
                f.PreferredCultureResolver.Received(1).Resolve();
                f.LookupCultureResolver.Received(1).Resolve(Arg.Any<string>());
            }

            [Fact]
            public void DerivesAliasFromValidEventDescriptionForSpecifiedCriteria()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();

                var applicationFilingEvent = (EntityModel.Event) events.Data.e3;

                var validEvent = new ValidEvent(new Criteria {Id = Fixture.Integer()},
                                                applicationFilingEvent,
                                                Fixture.String("Event Control1" + applicationFilingEvent.Description)).In(Db);
                applicationFilingEvent.ValidEvents.Add(validEvent);
                applicationFilingEvent.ValidEvents.Add(new ValidEvent(new Criteria {Id = Fixture.Integer()},
                                                                      applicationFilingEvent,
                                                                      Fixture.String("Event Control2" + applicationFilingEvent.Description)).In(Db));

                var r = f.Subject.MatchingItems("OPP", validEvent.CriteriaId).ToArray();

                Assert.Single(r);
                Assert.Single(r.Single().Alias.Split(';'));
                Assert.Equal(validEvent.Description, r.Single().Alias.Trim());
            }

            [Fact]
            public void MatchesOnDescriptionWhenNoTranslationRequired()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();

                var officialActionEvent = (EntityModel.Event) events.Data.e1;
                var applicationFilingEvent = (EntityModel.Event) events.Data.e3;

                applicationFilingEvent.ValidEvents.Add(
                                                       new ValidEvent(new Criteria {Id = Fixture.Integer()},
                                                                      applicationFilingEvent,
                                                                      Fixture.String("Event Control1" + applicationFilingEvent.Description)).In(Db));

                applicationFilingEvent.ValidEvents.Add(
                                                       new ValidEvent(new Criteria {Id = Fixture.Integer()},
                                                                      applicationFilingEvent,
                                                                      Fixture.String("Event Control2" + applicationFilingEvent.Description)).In(Db));
                f.LookupCultureResolver.Resolve(Arg.Any<string>()).Returns(new LookupCulture());

                var r = f.Subject.MatchingItems("OPP").ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(officialActionEvent.Id, r.First().Key);
                Assert.Equal(2, r.Last().Alias.Split(';').Length);
                Assert.Equal(applicationFilingEvent.ValidEvents.First().Description, r.Last().Alias.Split(';').First());
                Assert.Equal(applicationFilingEvent.ValidEvents.Last().Description, r.Last().Alias.Split(';').Last().Trim());
            }

            [Fact]
            public void ReturnAliasesWhenCriteriaSearch()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();

                var criteriaNo = events.CriteriaNo;

                var r = f.Subject.MatchingItems(string.Empty, criteriaNo);

                Assert.Equal(2, r.Length);
            }

            [Fact]
            public void ReturnEventsInDescriptionOrderWhenNoSearchEntered()
            {
                var f = new EventMatcherFixture(Db);

                f.Events();

                var r = f.Subject.MatchingItems().ToArray();

                Assert.Equal(Db.Set<EntityModel.Event>().AsQueryable().OrderBy(_ => _.Description).First().Id,
                             r.OrderBy(_ => _.Value).First().Key);
                Assert.Equal(Db.Set<EntityModel.Event>().AsQueryable().OrderBy(_ => _.Description).Last().Id,
                             r.OrderBy(_ => _.Value).Last().Key);
            }

            [Fact]
            public void ReturnsAllEventsWithNoAliasOrderByEventId()
            {
                var f = new EventMatcherFixture(Db);

                f.Events();

                var r = f.Subject.MatchingItems().ToArray();

                Assert.Equal(7, r.Length);
                Assert.Equal(Db.Set<EntityModel.Event>().AsQueryable().OrderBy(_ => _.Id).First().Id,
                             r.OrderBy(_ => _.Key).First().Key);
            }

            [Fact]
            public void ReturnsFilteredEventsOnClientImportanceLevelForExternalUser()
            {
                var f = new EventMatcherFixture(Db,null,true);

                f.Events();
                f.ImportanceLevelResolver.Resolve().Returns(2);

                var r = f.Subject.MatchingItems().ToArray();

                Assert.Single(r);
                Assert.Equal("VQ2", r[0].Code);

            }

            [Fact]
            public void ReturnsAllMatchingDescriptionsFromEventsAndEventControlTable()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();

                var officialActionEvent = (EntityModel.Event) events.Data.e1;
                var applicationFilingEvent = (EntityModel.Event) events.Data.e3;

                applicationFilingEvent.ValidEvents.Add(
                                                       new ValidEvent(new Criteria {Id = Fixture.Integer()},
                                                                      applicationFilingEvent,
                                                                      Fixture.String("Event Control1" + applicationFilingEvent.Description)).In(Db));

                applicationFilingEvent.ValidEvents.Add(
                                                       new ValidEvent(new Criteria {Id = Fixture.Integer()},
                                                                      applicationFilingEvent,
                                                                      Fixture.String("Event Control2" + applicationFilingEvent.Description)).In(Db));

                var r = f.Subject.MatchingItems("OPP").ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(officialActionEvent.Id, r.First().Key);
                Assert.Equal(2, r.Last().Alias.Split(';').Length);
                Assert.Equal(applicationFilingEvent.ValidEvents.First().Description, r.Last().Alias.Split(';').First());
                Assert.Equal(applicationFilingEvent.ValidEvents.Last().Description, r.Last().Alias.Split(';').Last().Trim());
            }

            [Fact]
            public void ReturnsDistinctAliasMatches()
            {
                var f = new EventMatcherFixture(Db);

                f.Events();

                var r = f.Subject.MatchingItems("alias for event V").ToArray();
                var match = r.Single();
                Assert.Equal(2, match.ValidEventDescription.Count());
                Assert.True(match.ValidEventDescription.All(match.Alias.Contains));
            }

            [Fact]
            public void ReturnsExactEventCodeMatchOnly()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();
                var eventSearched = events.Data.e7;

                var r = f.Subject.MatchingItems("V1").ToArray();

                Assert.Equal(eventSearched.Code, r.First().Code);
                Assert.Single(r);
            }

            [Fact]
            public void ReturnsExactEventNoMatchFirst()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();
                var eventSearched = events.Data.e7;

                var r = f.Subject.MatchingItems("2").ToArray();

                Assert.Equal(eventSearched.Code, r[0].Code);
            }

            [Fact]
            public void ReturnsExactMatchForDescriptionsAndThenContainsMatchForDescriptions()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();

                var filingDateEvent = (EntityModel.Event) events.Data.e4;
                var filingDataOpenActionEvent = (EntityModel.Event) events.Data.e5;

                var r = f.Subject.MatchingItems("Filing Date").ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(filingDateEvent.Id, r.First().Key);
                Assert.Equal(filingDataOpenActionEvent.Id, r.Last().Key);
            }

            [Fact]
            public void ReturnsExactMatchingEventCodeAndMatchingEventDescription()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();

                var officialActionEvent = (EntityModel.Event) events.Data.e1;
                var applicationFilingEvent = (EntityModel.Event) events.Data.e3;

                var r = f.Subject.MatchingItems("OPP").ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(officialActionEvent.Id, r.First().Key);
                Assert.Equal(applicationFilingEvent.Description, r.Last().Value);
            }

            [Fact]
            public void ReturnsExactMatchingEventCodeWhenEventCodeIsSearchedFor()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();
                var officialActionEvent = (EntityModel.Event) events.Data.e2;

                var r = f.Subject.MatchingItems(officialActionEvent.Id.ToString()).ToArray();

                Assert.True(r.Any());
                Assert.Equal(officialActionEvent.Code, r.Single().Code);
            }

            [Fact]
            public void ReturnsExactMatchingEventWhenNumberIsSearchedFor()
            {
                var f = new EventMatcherFixture(Db);

                var events = f.Events();
                var officialActionEvent = (EntityModel.Event) events.Data.e1;

                var r = f.Subject.MatchingItems(officialActionEvent.Id.ToString()).ToArray();

                Assert.Single(r);
                Assert.Equal(officialActionEvent.Id, r.Single().Key);
            }
        }

        public class EventMatcherFixture : IFixture<IEventMatcher>
        {
            readonly InMemoryDbContext _db;

            public EventMatcherFixture(InMemoryDbContext db, string culture = null, bool isExternal = false)
            {
                _db = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                LookupCultureResolver = Substitute.For<ILookupCultureResolver>();
                LookupCulture = !string.IsNullOrEmpty(culture) ? new LookupCulture(culture, culture) : new LookupCulture();
                LookupCultureResolver.Resolve(Arg.Any<string>()).Returns(LookupCulture);
                ImportanceLevelResolver = Substitute.For<IImportanceLevelResolver>();
                SecurityContext = Substitute.For<ISecurityContext>();

                var user = new User("user", isExternal).In(db);
                SecurityContext.User.Returns(_ => user);

                Subject = new EventMatcher(_db, PreferredCultureResolver, LookupCultureResolver, ImportanceLevelResolver, SecurityContext);
            }

            public LookupCulture LookupCulture { get; set; }
            public ILookupCultureResolver LookupCultureResolver { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public IImportanceLevelResolver ImportanceLevelResolver { get; }
            public ISecurityContext SecurityContext { get; }
            public IEventMatcher Subject { get; }

            public dynamic Events()
            {
                var critical = new Importance
                {
                    Level = "1",
                    Description = "Critical"
                };

                var important = new Importance
                {
                    Level = "2",
                    Description = "Important"
                };

                var normal = new Importance
                {
                    Level = "3",
                    Description = "Normal"
                };

                var e1 = new EntityModel.Event(Fixture.Integer())
                {
                    Code = "OPP",
                    Description = "Official Action 12 month Deadline",
                    ImportanceLevel = critical.Level,
                    InternalImportance = critical,
                    NumberOfCyclesAllowed = 2,
                    ValidEvents = new List<ValidEvent>()
                }.In(_db);

                var e2 = new EntityModel.Event(Fixture.Integer())
                {
                    Code = "USOA",
                    Description = "FINAL 3 month Office Action-Last Day",
                    ImportanceLevel = normal.Level,
                    InternalImportance = normal,
                    NumberOfCyclesAllowed = 5,
                    ValidEvents = new List<ValidEvent>()
                }.In(_db);

                var e3 = new EntityModel.Event(Fixture.Integer())
                {
                    Code = "DEWF",
                    Description = Fixture.String("OPP"),
                    ImportanceLevel = important.Level,
                    InternalImportance = important,
                    NumberOfCyclesAllowed = 3,
                    ValidEvents = new List<ValidEvent>()
                }.In(_db);

                var e4 = new EntityModel.Event(Fixture.Integer())
                {
                    Code = "XXX",
                    Description = "Filing Date",
                    ImportanceLevel = normal.Level,
                    InternalImportance = normal,
                    NumberOfCyclesAllowed = 3,
                    ValidEvents = new List<ValidEvent>()
                }.In(_db);

                var e5 = new EntityModel.Event(Fixture.Integer())
                {
                    Code = "YYY",
                    Description = Fixture.String("Filing Date for Open Action - Last Day"),
                    ImportanceLevel = critical.Level,
                    InternalImportance = critical,
                    NumberOfCyclesAllowed = 3,
                    ClientImportanceLevel = critical.Level,
                    ClientImportance = critical,
                    ValidEvents = new List<ValidEvent>()
                }.In(_db);

                var e6 = new EntityModel.Event(Fixture.Integer())
                {
                    Code = "VQ2",
                    Description = Fixture.String("Very Quality Law"),
                    ImportanceLevel = critical.Level,
                    InternalImportance = critical,
                    NumberOfCyclesAllowed = 7,
                    CategoryId = 444,
                    Category = new EntityModel.EventCategory(444) {Name = "Q Category"},
                    ClientImportanceLevel = normal.Level,
                    ClientImportance = normal,
                    ShouldPoliceImmediate = true,
                    ControllingAction = "VA",
                    Action = new Action("VQAction", null, 1, "VA"),
                    DraftEventId = e5.Id,
                    DraftEvent = e5,
                    IsAccountingEvent = true,
                    Notes = Fixture.String("VQ Notes"),
                    RecalcEventDate = true,
                    SuppressCalculation = false,
                    ValidEvents = new List<ValidEvent>()
                }.In(_db);

                var e7 = new EntityModel.Event(Fixture.Integer())
                {
                    Id = 2,
                    Code = "V1",
                    Description = Fixture.String("V1 Event Description"),
                    NumberOfCyclesAllowed = 1,
                    ValidEvents = new List<ValidEvent>()
                }.In(_db);

                var critieriaNo = Fixture.Integer();
                var ve1 = new ValidEvent(critieriaNo, e7.Id, "alias for event V1").In(_db);
                var ve2 = new ValidEvent(Fixture.Integer(), e7.Id, "alias for event V1").In(_db);
                var ve3 = new ValidEvent(Fixture.Integer(), e7.Id, "Open Action - Last Day").In(_db);
                var ve4 = new ValidEvent(critieriaNo, e6.Id, "alias VQ2").In(_db);

                e6.ValidEvents.Add(ve4);
                e7.ValidEvents.Add(ve3);
                e7.ValidEvents.Add(ve2);
                e7.ValidEvents.Add(ve1);

                return new {Data = new {e1, e2, e3, e4, e5, e6, e7}, CriteriaNo = critieriaNo};
            }
        }
    }
}