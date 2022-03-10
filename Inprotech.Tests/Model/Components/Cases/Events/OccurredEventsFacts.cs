using System.Linq;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Rules;
using Xunit;
using our = InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Model.Components.Cases.Events
{
    public class OccurredEventsFacts
    {
        public class CaseSetup
        {
            readonly InMemoryDbContext _db;

            public our.Case Case;

            public CaseSetup(InMemoryDbContext db)
            {
                _db = db;
                Case = new our.Case("IRN", new our.Country(), new our.CaseType(), new our.PropertyType()).In(db);
            }

            public CaseSetup WithCaseEvent(string desc, bool occurred = true)
            {
                var ce = new our.CaseEvent(
                                           Case.Id,
                                           new Event
                                           {
                                               Description = desc
                                           }.In(_db).Id,
                                           Fixture.Short());

                ce.IsOccurredFlag = occurred ? 1 : 0;
                Case.CaseEvents.Add(ce);
                return this;
            }

            public CaseSetup WithOpenActionThatHasNotBeenPoliced()
            {
                Case.OpenActions.Add(
                                     new our.OpenAction(
                                                        new our.Action(), Case, 1, "status", null, true).In(_db));

                return this;
            }

            public CaseSetup ConfigureValidEventForOpenActionCriteria(
                our.CaseEvent ce,
                string specificDesc,
                bool isOpen = true)
            {
                var c = new Criteria().In(_db);
                Case.OpenActions.Add(new our.OpenAction(new our.Action().In(_db), Case, 1, "status", c, isOpen));
                var e = _db.Set<Event>().Single(_ => _.Id == ce.EventNo);
                new ValidEvent(c, e, specificDesc).In(_db);
                return this;
            }
        }

        public class ForMethod : FactBase
        {
            [Fact]
            public void CaterForSituationWhereOpenActionDoesNotHaveCriteria()
            {
                var setup = new CaseSetup(Db)
                            .WithCaseEvent("Renewal Date")
                            .WithOpenActionThatHasNotBeenPoliced();

                var f = new OccurredEventsFixture(Db);

                var r = f.Subject.For(setup.Case).ToArray();

                Assert.NotEmpty(r);

                Assert.Same("Renewal Date", r.Single().Description);
            }

            [Fact]
            public void OrdersReturnByDescription()
            {
                var @case = new CaseSetup(Db)
                            .WithCaseEvent("Renewal Date")
                            .WithCaseEvent("Application Filing Date")
                            .Case;

                var f = new OccurredEventsFixture(Db);

                var result = f.Subject.For(@case);

                Assert.Same("Application Filing Date", result.First().Description);
            }

            [Fact]
            public void ReturnsDescriptionFromOpenActionCriteria()
            {
                var setup = new CaseSetup(Db)
                    .WithCaseEvent("Renewal Date");

                var e = Db.Set<Event>().Single();

                /* valid event for c1 */
                var c1 = new Criteria().In(Db);
                setup.Case.OpenActions.Add(
                                           new our.OpenAction(new our.Action(), setup.Case, 1, "status", c1, true).In(Db));
                new ValidEvent(c1, e, "Open Action Event Description").In(Db);

                /* valid event for c2 */
                var c2 = new Criteria().In(Db);
                setup.Case.CaseEvents.Single().CreatedByCriteriaKey = c2.Id;
                new ValidEvent(c2, e, "Created By Criteria Event Description").In(Db);

                var f = new OccurredEventsFixture(Db);

                var result = f.Subject.For(setup.Case).ToArray();

                Assert.Same("Open Action Event Description", result.Single().Description);
            }

            [Fact]
            public void ReturnsOccurredEventsOnly()
            {
                const bool occurred = true;

                var @case = new CaseSetup(Db)
                            .WithCaseEvent("due date", !occurred)
                            .WithCaseEvent("occurred event")
                            .Case;

                var f = new OccurredEventsFixture(Db);

                var result = f.Subject.For(@case);

                Assert.Single(result);
            }

            [Fact]
            public void UsesDescriptionFromCaseEventCreationCriteria()
            {
                var setup = new CaseSetup(Db)
                    .WithCaseEvent("Renewal Date");

                var c = new Criteria().In(Db);
                setup.Case.CaseEvents.Single().CreatedByCriteriaKey = c.Id;

                var e = Db.Set<Event>().Single();
                new ValidEvent(c, e, "Specific Renewal Date").In(Db);

                var f = new OccurredEventsFixture(Db);

                var result = f.Subject.For(setup.Case).ToArray();

                Assert.Same("Specific Renewal Date", result.Single().Description);
            }

            [Fact]
            public void UsesDescriptionFromOpenActionCriteria()
            {
                const bool actionIsOpened = true;

                var setup = new CaseSetup(Db)
                            .WithCaseEvent("Renewal Date")
                            .WithCaseEvent("Application Filing Date");

                setup.ConfigureValidEventForOpenActionCriteria(
                                                               setup.Case.CaseEvents.First(),
                                                               "Specific Renewal Date desc");
                setup.ConfigureValidEventForOpenActionCriteria(
                                                               setup.Case.CaseEvents.Last(),
                                                               "Specific Application Filing Date desc",
                                                               !actionIsOpened);

                var f = new OccurredEventsFixture(Db);

                var result = f.Subject.For(setup.Case).ToArray();

                Assert.Same("Application Filing Date", result.First().Description);

                Assert.Same("Specific Renewal Date desc", result.Last().Description);
            }
        }

        public class OccurredEventsFixture : IFixture<OccurredEvents>
        {
            public OccurredEventsFixture(InMemoryDbContext db)
            {
                Subject = new OccurredEvents(db);
            }

            public OccurredEvents Subject { get; }
        }
    }
}