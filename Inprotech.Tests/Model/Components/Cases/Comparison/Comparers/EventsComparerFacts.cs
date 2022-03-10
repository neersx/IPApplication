using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Translations;
using InprotechKaizen.Model.Components.Cases.Events;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using Event = InprotechKaizen.Model.Cases.Events.Event;
using EventBuilder = Inprotech.Tests.Web.Builders.Model.Cases.Events.EventBuilder;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class EventsComparerFacts
    {
        public class CompareMethod : FactBase
        {
            public CompareMethod()
            {
                _nonCyclicEvent = new EventBuilder
                    {
                        NumCyclesAllowed = 1
                    }.Build()
                     .In(Db);

                _cyclicEvent = new EventBuilder().Build().In(Db);
            }

            readonly EventComparisonScenarioBuilder _scenarioBuilder = new EventComparisonScenarioBuilder();

            readonly MatchingNumberEventComparisonScenarioBuilder _scenarioBuilderMatchingNumberEvent =
                new MatchingNumberEventComparisonScenarioBuilder();

            readonly Event _nonCyclicEvent;

            readonly Event _cyclicEvent;

            [Fact]
            public void CallsDateAlignerForCyclicEvents()
            {
                var f = new EventsComparerFixture(Db);

                var @case = new InprotechCaseBuilder(Db)
                            .WithCaseEvent(_cyclicEvent.Id, Fixture.Today())
                            .Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case,
                                  _scenarioBuilder.Build(
                                                         new DataMapping.Builders.EventBuilder {EventId = _cyclicEvent.Id, EventDate = Fixture.Today()}.Build(),
                                                         new DataMapping.Builders.EventBuilder {EventId = _cyclicEvent.Id, EventDate = Fixture.PastDate()}.Build(),
                                                         new DataMapping.Builders.EventBuilder {EventId = _cyclicEvent.Id, EventDate = Fixture.FutureDate()}.Build()
                                                        ), cr);

                Assert.Equal(3, cr.Events.Count());
            }

            [Fact]
            public void ConsidersValidDescriptions()
            {
                var f = new EventsComparerFixture(Db)
                    .WithValidDescriptionFor(_nonCyclicEvent, "hello world");

                var @case = new InprotechCaseBuilder(Db)
                            .WithCaseEvent(_nonCyclicEvent.Id, Fixture.Today())
                            .Build();

                _scenarioBuilder.Event =
                    new DataMapping.Builders.EventBuilder {EventId = _nonCyclicEvent.Id, EventDate = Fixture.PastDate()}.Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new[]
                {
                    _scenarioBuilder.Build()
                }, cr);

                Assert.Single(cr.Events);
                Assert.Equal("hello world", cr.Events.Single().EventType);
            }

            [Fact]
            public void DoesNotCompareEventsAlreadyUsedInOfficialNumberComparer()
            {
                var f = new EventsComparerFixture(Db);

                var sameInputCode = Fixture.String();

                var relatedEventOfANumberType = new EventBuilder
                    {
                        NumCyclesAllowed = 1
                    }.Build()
                     .In(Db);

                new NumberType("A", "ApplicationNo", null).In(Db);

                var @case = new InprotechCaseBuilder(Db)
                    .Build();

                _scenarioBuilderMatchingNumberEvent.Event =
                    new MatchingNumberEvent
                    {
                        EventCode = sameInputCode
                    };

                _scenarioBuilder.Event =
                    new DataMapping.Builders.EventBuilder
                    {
                        EventCode = sameInputCode,
                        EventId = relatedEventOfANumberType.Id,
                        EventDate = Fixture.Today()
                    }.Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new ComparisonScenario[]
                {
                    _scenarioBuilder.Build(),
                    _scenarioBuilderMatchingNumberEvent.Build()
                }, cr);

                Assert.Empty(cr.Events);
            }

            [Fact]
            public void DoesNotReturnIfNothingWasMapped()
            {
                var f = new EventsComparerFixture(Db);

                var @case = new InprotechCaseBuilder(Db)
                    .Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, Enumerable.Empty<ComparisonScenario<InprotechKaizen.Model.Components.Cases.Comparison.Models.Event>>(), cr);

                Assert.Empty(cr.Events);
            }

            [Fact]
            public void PreservesSourceOrder()
            {
                var f = new EventsComparerFixture(Db);

                var @case = new InprotechCaseBuilder(Db)
                            .WithCaseEvent(_cyclicEvent.Id, Fixture.Today())
                            .Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case,
                                  _scenarioBuilder.Build(
                                                         new DataMapping.Builders.EventBuilder {EventId = _cyclicEvent.Id, EventDate = Fixture.Today()}.Build(),
                                                         new DataMapping.Builders.EventBuilder {EventId = _cyclicEvent.Id, EventDate = Fixture.PastDate()}.Build(),
                                                         new DataMapping.Builders.EventBuilder {EventId = _cyclicEvent.Id, EventDate = Fixture.FutureDate()}.Build()
                                                        ),
                                  cr);

                var r = cr.Events.ToArray();

                var r1 = r.ElementAt(0);
                var r2 = r.ElementAt(1);
                var r3 = r.ElementAt(2);

                Assert.Equal(Fixture.Today(), r1.EventDate.TheirValue);
                Assert.Equal(Fixture.PastDate(), r2.EventDate.TheirValue);
                Assert.Equal(Fixture.FutureDate(), r3.EventDate.TheirValue);
            }

            [Fact]
            public void ReturnsFirstEventForComparisonOfNonCyclicEvent()
            {
                var f = new EventsComparerFixture(Db);

                var @case = new InprotechCaseBuilder(Db)
                            .WithCaseEvent(_nonCyclicEvent.Id, Fixture.Today())
                            .Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case,
                                  _scenarioBuilder.Build(
                                                         new DataMapping.Builders.EventBuilder {EventId = _nonCyclicEvent.Id, EventDate = Fixture.Today()}.Build(),
                                                         new DataMapping.Builders.EventBuilder {EventId = _nonCyclicEvent.Id, EventDate = Fixture.PastDate()}.Build(),
                                                         new DataMapping.Builders.EventBuilder {EventId = _nonCyclicEvent.Id, EventDate = Fixture.FutureDate()}.Build()
                                                        ),
                                  cr);

                Assert.Single(cr.Events);
                Assert.Equal(_nonCyclicEvent.Description, cr.Events.Single().EventType);
                Assert.Equal(Fixture.Today(), cr.Events.Single().EventDate.TheirValue);
                Assert.Equal(Fixture.Today(), cr.Events.Single().EventDate.OurValue);
                Assert.Equal((short) 1, cr.Events.Single().Cycle);
                Assert.False(cr.Events.Single().EventDate.Updateable.GetValueOrDefault());
                Assert.False(cr.Events.Single().EventDate.Different.GetValueOrDefault());
            }

            [Fact]
            public void ReturnsNonCylicEventMatched()
            {
                var f = new EventsComparerFixture(Db);

                var @case = new InprotechCaseBuilder(Db)
                            .WithCaseEvent(_nonCyclicEvent.Id, Fixture.Today())
                            .Build();

                _scenarioBuilder.Event =
                    new DataMapping.Builders.EventBuilder {EventId = _nonCyclicEvent.Id, EventDate = Fixture.Today()}.Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new[]
                {
                    _scenarioBuilder.Build()
                }, cr);

                Assert.Single(cr.Events);
                Assert.Equal(_nonCyclicEvent.Description, cr.Events.Single().EventType);
                Assert.Equal(Fixture.Today(), cr.Events.Single().EventDate.TheirValue);
                Assert.Equal(Fixture.Today(), cr.Events.Single().EventDate.OurValue);
                Assert.Equal((short) 1, cr.Events.Single().Cycle);
                Assert.False(cr.Events.Single().EventDate.Updateable.GetValueOrDefault());
                Assert.False(cr.Events.Single().EventDate.Different.GetValueOrDefault());
            }

            [Fact]
            public void ReturnsNonCylicEventUnmatched()
            {
                var f = new EventsComparerFixture(Db);

                var @case = new InprotechCaseBuilder(Db)
                            .WithCaseEvent(_nonCyclicEvent.Id, Fixture.Today())
                            .Build();

                _scenarioBuilder.Event =
                    new DataMapping.Builders.EventBuilder {EventId = _nonCyclicEvent.Id, EventDate = Fixture.PastDate()}.Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new[]
                {
                    _scenarioBuilder.Build()
                }, cr);

                Assert.Single(cr.Events);
                Assert.Equal(_nonCyclicEvent.Description, cr.Events.Single().EventType);
                Assert.Equal(Fixture.PastDate(), cr.Events.Single().EventDate.TheirValue);
                Assert.Equal(Fixture.Today(), cr.Events.Single().EventDate.OurValue);
                Assert.Equal((short) 1, cr.Events.Single().Cycle);
                Assert.True(cr.Events.Single().EventDate.Updateable.GetValueOrDefault());
                Assert.True(cr.Events.Single().EventDate.Different.GetValueOrDefault());
            }

            [Fact]
            public void ReturnsNonCylicEventWithNoMatch()
            {
                var f = new EventsComparerFixture(Db);

                var @case = new InprotechCaseBuilder(Db).Build();

                _scenarioBuilder.Event =
                    new DataMapping.Builders.EventBuilder {EventId = _nonCyclicEvent.Id, EventDate = Fixture.Today()}.Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new[]
                {
                    _scenarioBuilder.Build()
                }, cr);

                Assert.Single(cr.Events);
                Assert.Equal(_nonCyclicEvent.Description, cr.Events.Single().EventType);
                Assert.Equal(Fixture.Today(), cr.Events.Single().EventDate.TheirValue);
                Assert.Null(cr.Events.Single().EventDate.OurValue);
                Assert.Null(cr.Events.Single().Cycle);
                Assert.True(cr.Events.Single().EventDate.Updateable.GetValueOrDefault());
                Assert.True(cr.Events.Single().EventDate.Different.GetValueOrDefault());
            }
        }
    }

    internal class EventsComparerFixture : IFixture<EventsComparer>
    {
        public EventsComparerFixture(InMemoryDbContext db)
        {
            DatesAligner = Substitute.For<IDatesAligner>();
            DatesAligner.Align(Arg.Any<IEnumerable<Date<PtoDateInfo>>>(), Arg.Any<IEnumerable<Date<short>>>())
                        .Returns(
                                 x => ((IEnumerable<Date<PtoDateInfo>>) x[0])
                                     .Select(_ => new DatePair<PtoDateInfo, short?>
                                     {
                                         DateTimeLhs = _.DateTime,
                                         DateTimeRhs = _.DateTime,
                                         RefLhs = _.Ref,
                                         RefRhs = Fixture.Short()
                                     }));

            ValidEventResolver = Substitute.For<IValidEventResolver>();

            EventDescriptionTranslator = Substitute.For<IEventDescriptionTranslator>();
            EventDescriptionTranslator.Translate(Arg.Any<IEnumerable<InprotechKaizen.Model.Components.Cases.Comparison.Results.Event>>())
                                      .Returns(x => x[0]);

            Subject = new EventsComparer(db, DatesAligner, ValidEventResolver, EventDescriptionTranslator);

            MasterDataBuilder.BuildNumberTypeAndRelatedEvent(db, "A", "Application", -4);
        }

        public IDatesAligner DatesAligner { get; set; }

        public IEventDescriptionTranslator EventDescriptionTranslator { get; set; }

        public IValidEventResolver ValidEventResolver { get; set; }

        public EventsComparer Subject { get; }

        public EventsComparerFixture WithValidDescriptionFor(Event @event,
                                                             string validEventDescription)
        {
            ValidEventResolver.Resolve(Arg.Any<Case>(), @event)
                              .Returns(new ValidEventBuilder
                              {
                                  Description = validEventDescription,
                                  Event = @event,
                                  NumberOfCyclesAllowed = @event.NumberOfCyclesAllowed
                              }.Build());
            return this;
        }
    }
}