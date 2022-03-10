using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.Lists;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;
using Entity = InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Web.Lists
{
    public class EventsControllerFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ShouldForwardCorrectQueryToEventMatcher()
            {
                var query = Fixture.String();

                var fixture = new EventsControllerFixture(Db)
                    .WithSearchResult();

                fixture.Subject.Get(query);

                fixture.EventMatcher.Received(1).MatchingItems(query);
            }

            [Fact]
            public void ShouldGetResultWithKeyValue()
            {
                var query = Fixture.String();

                var e1 = new EventBuilder().Build().In(Db);

                var e2 = new EventBuilder().Build().In(Db);

                var m1 = new MatchedEvent
                {
                    Key = e1.Id,
                    Value = Fixture.String(),
                    Code = Fixture.String()
                };

                var m2 = new MatchedEvent
                {
                    Key = e2.Id,
                    Value = Fixture.String(),
                    Code = Fixture.String()
                };

                var fixture = new EventsControllerFixture(Db)
                    .WithSearchResult(m1, m2);

                var result = fixture.Subject.Get(query).ToArray();

                Assert.Equal(m1.Key, result[0].Key);
                Assert.Equal(m1.Code, result[0].Code);
                Assert.Equal(m1.Value, result[0].Value);

                Assert.Equal(m2.Key, result[1].Key);
                Assert.Equal(m2.Code, result[1].Code);
                Assert.Equal(m2.Value, result[1].Value);
            }

            [Fact]
            public void ShouldGetResultWithOtherColumns()
            {
                var query = Fixture.String();

                var e = new EventBuilder().Build().In(Db);

                e.Notes = Fixture.String();
                e.Category = new Entity.EventCategory
                {
                    Name = Fixture.String()
                }.In(Db);

                var m = new MatchedEvent
                {
                    Key = e.Id,
                    Value = Fixture.String(),
                    Code = Fixture.String(),
                    MaxCycles = Fixture.Short(),
                    Importance = Fixture.String(),
                    ImportanceLevel = Fixture.String()
                };

                var fixture = new EventsControllerFixture(Db)
                    .WithSearchResult(m);

                var result = fixture.Subject.Get(query).ToArray();

                Assert.Equal(m.Key, result[0].Key);
                Assert.Equal(m.Code, result[0].Code);
                Assert.Equal(m.Value, result[0].Value);
                Assert.Equal(m.MaxCycles, result[0].Cycles);
                Assert.Equal(m.Importance, result[0].ImportanceDesc);
                Assert.Equal(m.ImportanceLevel, result[0].ImportanceLevel);
                Assert.Equal(e.Category.Name, result[0].Category);
                Assert.Equal(e.Notes, result[0].Definition);
                Assert.False(result[0].InUse);
            }

            [Fact]
            public void ShouldReturnEventInUseIfReferencedByValidEvents()
            {
                var query = Fixture.String();

                var e = new EventBuilder().Build().In(Db);

                e.Notes = Fixture.String();
                e.Category = new Entity.EventCategory
                {
                    Name = Fixture.String()
                }.In(Db);

                var m = new MatchedEvent
                {
                    Key = e.Id,
                    ValidEventDescription = new[]
                    {
                        "Used by some other Valid Event"
                    }
                };

                var fixture = new EventsControllerFixture(Db)
                    .WithSearchResult(m);

                var result = fixture.Subject.Get(query).ToArray();

                Assert.True(result[0].InUse);
            }
        }

        public class EventsControllerFixture : IFixture<EventsController>
        {
            public EventsControllerFixture(InMemoryDbContext db)
            {
                EventMatcher = Substitute.For<IEventMatcher>();

                Subject = new EventsController(db, EventMatcher);
            }

            public IEventMatcher EventMatcher { get; set; }

            public EventsController Subject { get; }

            public EventsControllerFixture WithSearchResult(params MatchedEvent[] matchedEvents)
            {
                EventMatcher.MatchingItems(Arg.Any<string>())
                            .Returns(matchedEvents ?? new MatchedEvent [0]);
                return this;
            }
        }
    }
}