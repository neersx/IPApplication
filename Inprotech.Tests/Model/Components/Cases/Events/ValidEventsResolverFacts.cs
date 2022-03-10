using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Events;
using NSubstitute;
using Xunit;
using CasesModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Model.Components.Cases.Events
{
    public class ValidEventsResolverFacts
    {
        public class ResolveMethod : FactBase
        {
            [Fact]
            public void ResolvesValidEvents()
            {
                var f = new ValidEventsResolverFixture(Db);

                var event1 = new EventBuilder {Description = "event 1"}.Build().In(Db);
                var event2 = new EventBuilder {Description = "event 2"}.Build().In(Db);
                var event3 = new EventBuilder {Description = "event 3"}.Build().In(Db);

                var @case = new CaseBuilder().Build().In(Db);

                @case.CaseEvents.Add(
                                     new CasesModel.CaseEvent(@case.Id, event1.Id, 1)
                                    );

                @case.CaseEvents.Add(
                                     new CasesModel.CaseEvent(@case.Id, event2.Id, 1)
                                    );

                @case.CaseEvents.Add(
                                     new CasesModel.CaseEvent(@case.Id, event3.Id, 1)
                                    );

                var r = f.Subject.Resolve(@case.Id, new[]
                {
                    event1.Id,
                    event2.Id,
                    event3.Id
                }).ToArray();

                Assert.Equal("specific event 1", r[0].Description);
                Assert.Equal("specific event 2", r[1].Description);
                Assert.Equal("specific event 3", r[2].Description);
            }
        }

        public class ValidEventsResolverFixture : IFixture<ValidEventsResolver>
        {
            public ValidEventsResolverFixture(InMemoryDbContext db)
            {
                ValidEventResolver = Substitute.For<IValidEventResolver>();
                ValidEventResolver.Resolve(
                                           Arg.Any<CasesModel.Case>(),
                                           Arg.Any<Event>())
                                  .Returns(
                                           x =>
                                           {
                                               var @event = (Event) x[1];
                                               return new ValidEventBuilder
                                               {
                                                   Description = "specific " + @event.Description
                                               }.Build().In(db);
                                           }
                                          );

                Subject = new ValidEventsResolver(db, ValidEventResolver);
            }

            public IValidEventResolver ValidEventResolver { get; set; }

            public ValidEventsResolver Subject { get; set; }
        }
    }
}