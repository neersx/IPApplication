using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Events;
using Xunit;
using CasesModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Model.Components.Cases.Events
{
    public class ValidEventResolverFacts
    {
        public class ResolveMethod : FactBase
        {
            [Fact]
            public void ReturnsNothing()
            {
                var f = new ValidEventResolverFixture(Db);

                var scenario = new Scenario(Db);

                Assert.Null(f.Subject.Resolve(scenario.Case, scenario.Event.Id));
            }

            [Fact]
            public void ReturnsValidEventFromCriteriaOfTheControllingAction()
            {
                var f = new ValidEventResolverFixture(Db);

                var scenario = new Scenario(Db)
                    .WithValidEventForControllingActionCriteria("specific event description");

                var r = f.Subject.Resolve(scenario.Case, scenario.Event.Id);

                Assert.Equal("specific event description", r.Description);
            }

            [Fact]
            public void ReturnValidEventIfReferencedInAnyOpenActionsAgainstTheCase()
            {
                var f = new ValidEventResolverFixture(Db);

                var scenario = new Scenario(Db)
                    .WithValidEventInReferencedCriteria("specific event description");

                var r = f.Subject.Resolve(scenario.Case, scenario.Event.Id);

                Assert.Equal("specific event description", r.Description);
            }
        }

        public class Scenario
        {
            readonly InMemoryDbContext _db;

            public Scenario(InMemoryDbContext db)
            {
                _db = db;

                Case = new CaseBuilder().Build().In(db);

                Event = new EventBuilder().Build().In(db);

                Action = new ActionBuilder().Build().In(db);

                Case.CaseEvents.Add(new CasesModel.CaseEvent(Case.Id, Event.Id, 1)
                {
                    CreatedByActionKey = Action.Code
                });
            }

            public CasesModel.Case Case { get; }

            public Event Event { get; }

            public CasesModel.Action Action { get; }

            public Scenario WithValidEventForControllingActionCriteria(string validEventDescription)
            {
                Event.ControllingAction = Action.Code;

                var criteria = new CriteriaBuilder
                               {
                                   Action = Action
                               }
                               .Build()
                               .In(_db);

                new ValidEventBuilder
                    {
                        Criteria = criteria,
                        Event = Event,
                        Description = validEventDescription
                    }
                    .Build()
                    .In(_db);

                Case.OpenActions.Add(
                                     new CasesModel.OpenAction(Action, Case, 1, Fixture.String(), criteria));

                return this;
            }

            public Scenario WithValidEventInReferencedCriteria(string validEventDescription)
            {
                Event.ControllingAction = null;

                var criteria = new CriteriaBuilder
                               {
                                   Action = Action
                               }
                               .Build()
                               .In(_db);

                new ValidEventBuilder
                    {
                        Criteria = criteria,
                        Event = Event,
                        Description = validEventDescription
                    }
                    .Build()
                    .In(_db);

                Case.OpenActions.Add(
                                     new CasesModel.OpenAction(Action, Case, 1, Fixture.String(), criteria));

                return this;
            }
        }

        public class ValidEventResolverFixture : IFixture<ValidEventResolver>
        {
            public ValidEventResolverFixture(InMemoryDbContext db)
            {
                Subject = new ValidEventResolver(db);
            }

            public ValidEventResolver Subject { get; set; }
        }
    }
}