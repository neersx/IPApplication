using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using Event = InprotechKaizen.Model.Components.Cases.Comparison.Results.Event;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Updaters
{
    public class EventUpdaterFacts
    {
        public class AddOrUpdateEventMethod : FactBase
        {
            [Fact]
            public void AddsEventIfNotFound()
            {
                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {EventNo = -1, Cycle = 1}.BuildForCase(@case);

                var newEventNo = Fixture.Integer();
                var newDate = Fixture.PastDate();
                var f = new EventUpdaterFixture(Db);

                f.ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns(new ValidEvent {NumberOfCyclesAllowed = 1});

                var result = f.Subject.AddOrUpdateEvent(@case, newEventNo, newDate, 1);

                Assert.Equal(2, @case.CaseEvents.Count);
                Assert.Equal(newEventNo, @case.CaseEvents.Last().EventNo);
                Assert.Equal(newDate, @case.CaseEvents.Last().EventDate);
                Assert.Equal(1, @case.CaseEvents.Last().Cycle);
                Assert.Equal(1, @case.CaseEvents.Last().IsOccurredFlag);
                Assert.IsType<PoliceCaseEvent>(result);
            }

            [Fact]
            public void CreatesFirstCycleForNotFoundCyclicEvent()
            {
                var @case = new CaseBuilder().Build();

                var newDate = Fixture.PastDate();
                var f = new EventUpdaterFixture(Db);

                f.ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns(new ValidEvent {NumberOfCyclesAllowed = 99});

                var result = f.Subject.AddOrUpdateEvent(@case, -1, newDate, 55);

                Assert.Equal(1, @case.CaseEvents.Count);
                Assert.Equal(1, @case.CaseEvents.First().Cycle);
                Assert.Equal(-1, @case.CaseEvents.First().EventNo);
                Assert.Equal(newDate, @case.CaseEvents.First().EventDate);
                Assert.Equal(1, @case.CaseEvents.First().IsOccurredFlag);
                Assert.IsType<PoliceCaseEvent>(result);
            }

            [Fact]
            public void CreatesTheNextCycleIfCycleInstanceNotFound()
            {
                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {EventNo = -1, Cycle = 1}.BuildForCase(@case);

                var newDate = Fixture.PastDate();
                var f = new EventUpdaterFixture(Db);

                f.ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns(new ValidEvent {NumberOfCyclesAllowed = 99});

                const short dataSourceCycle = 7;
                var result = f.Subject.AddOrUpdateEvent(@case, -1, newDate, dataSourceCycle);

                Assert.Equal(2, @case.CaseEvents.Count);
                Assert.Equal(2, @case.CaseEvents.Last().Cycle);
                Assert.Equal(-1, @case.CaseEvents.Last().EventNo);
                Assert.Equal(newDate, @case.CaseEvents.Last().EventDate);
                Assert.Equal(1, @case.CaseEvents.Last().IsOccurredFlag);
                Assert.IsType<PoliceCaseEvent>(result);
            }

            [Fact]
            public void UpdatesAsTodayWhenNoDatePassed()
            {
                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {EventNo = -1, EventDate = Fixture.PastDate(), Cycle = 1}.BuildForCase(@case);

                var f = new EventUpdaterFixture(Db);

                f.ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns(new ValidEvent {NumberOfCyclesAllowed = 99});

                f.Subject.AddOrUpdateEvent(@case, -1, null, 1);

                Assert.Equal(f.Today(), @case.CaseEvents.Single(c => c.EventNo == -1).EventDate);
            }

            [Fact]
            public void UpdatesEvent()
            {
                var eventNo = Fixture.Integer();
                var cycle = Fixture.Short();
                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {EventNo = eventNo, Cycle = cycle}.BuildForCase(@case);
                var f = new EventUpdaterFixture(Db);

                var newDate = Fixture.PastDate();
                var result = f.Subject.AddOrUpdateEvent(@case, eventNo, newDate, cycle);

                Assert.Equal(newDate, @case.CaseEvents.First().EventDate);
                Assert.IsType<PoliceCaseEvent>(result);
            }

            [Fact]
            public void UpdatesMatchingEventCycle()
            {
                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {EventNo = -1, Cycle = 2}.BuildForCase(@case);

                var newDate = Fixture.PastDate();
                var f = new EventUpdaterFixture(Db);

                f.ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns(new ValidEvent {NumberOfCyclesAllowed = 99});

                var result = f.Subject.AddOrUpdateEvent(@case, -1, newDate, 2);

                Assert.Equal(1, @case.CaseEvents.Count);
                Assert.Equal(2, @case.CaseEvents.First().Cycle);
                Assert.Equal(-1, @case.CaseEvents.First().EventNo);
                Assert.Equal(newDate, @case.CaseEvents.First().EventDate);
                Assert.IsType<PoliceCaseEvent>(result);
            }
        }

        public class AddOrUpdateEventsMethod : FactBase
        {
            [Fact]
            public void AddsOrUpdatesEachEvent()
            {
                var @case = new CaseBuilder().Build();

                new CaseEventBuilder {EventNo = -1, Cycle = 1}.BuildForCase(@case);

                var comparisonEvent1 = new Event
                {
                    EventNo = -1,
                    Cycle = 1,
                    EventDate = new Value<DateTime?>().AsUpdatedValue(null, Fixture.PastDate())
                };

                var comparisonEvent2 = new Event
                {
                    EventNo = -2,
                    Cycle = 2,
                    EventDate = new Value<DateTime?>().AsUpdatedValue(null, Fixture.Today())
                };

                var validEventResolver = Substitute.For<IValidEventResolver>();
                validEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns(new ValidEvent {NumberOfCyclesAllowed = 99});

                var subject = Substitute.ForPartsOf<EventUpdater>(Db, validEventResolver, (Func<DateTime>) Fixture.Today);

                var result = subject.AddOrUpdateEvents(@case, new[] {comparisonEvent1, comparisonEvent2}).ToArray();

                Assert.NotEmpty(result);

                subject.Received(1)
                       .AddOrUpdateEvent(@case, comparisonEvent1.EventNo.Value, comparisonEvent1.EventDate.TheirValue.Value,
                                         comparisonEvent1.Cycle);

                subject.Received(1)
                       .AddOrUpdateEvent(@case, comparisonEvent2.EventNo.Value, comparisonEvent2.EventDate.TheirValue.Value,
                                         comparisonEvent2.Cycle);
            }
        }

        public class AddOrUpdateDueDateEvent : FactBase
        {
            [Fact]
            public void AddsEventIfNotFound()
            {
                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {EventNo = -1, Cycle = 1}.BuildForCase(@case);

                var newEventNo = Fixture.Integer();
                var newDate = Fixture.FutureDate();
                var f = new EventUpdaterFixture(Db);

                f.ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns(new ValidEvent {NumberOfCyclesAllowed = 1});

                var result = f.Subject.AddOrUpdateDueDateEvent(@case, newEventNo, newDate, 1);

                Assert.Equal(2, @case.CaseEvents.Count);
                Assert.Equal(newEventNo, @case.CaseEvents.Last().EventNo);
                Assert.Equal(newDate, @case.CaseEvents.Last().EventDueDate);
                Assert.Equal(1, @case.CaseEvents.Last().Cycle);
                Assert.Equal(0, @case.CaseEvents.Last().IsOccurredFlag);
                Assert.Equal(1, @case.CaseEvents.Last().IsDateDueSaved);
                Assert.IsType<PoliceCaseEvent>(result);
            }

            [Fact]
            public void CreatesFirstCycleForNotFoundCyclicEvent()
            {
                var @case = new CaseBuilder().Build();

                var newDate = Fixture.FutureDate();
                var f = new EventUpdaterFixture(Db);

                f.ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns(new ValidEvent {NumberOfCyclesAllowed = 99});

                var result = f.Subject.AddOrUpdateDueDateEvent(@case, -1, newDate, 55);

                Assert.Equal(1, @case.CaseEvents.Count);
                Assert.Equal(1, @case.CaseEvents.First().Cycle);
                Assert.Equal(-1, @case.CaseEvents.First().EventNo);
                Assert.Equal(newDate, @case.CaseEvents.First().EventDueDate);
                Assert.Equal(0, @case.CaseEvents.First().IsOccurredFlag);
                Assert.Equal(1, @case.CaseEvents.Last().IsDateDueSaved);
                Assert.IsType<PoliceCaseEvent>(result);
            }

            [Fact]
            public void UpdatesEvent()
            {
                var eventNo = Fixture.Integer();
                var cycle = Fixture.Short();
                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {EventNo = eventNo, Cycle = cycle}.BuildForCase(@case);
                var f = new EventUpdaterFixture(Db);

                var newDate = Fixture.FutureDate();
                var result = f.Subject.AddOrUpdateDueDateEvent(@case, eventNo, newDate, cycle);

                Assert.Equal(newDate, @case.CaseEvents.First().EventDueDate);
                Assert.IsType<PoliceCaseEvent>(result);
            }

            [Fact]
            public void UpdatesMatchingEventCycle()
            {
                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {EventNo = -1, Cycle = 2}.BuildForCase(@case);

                var newDate = Fixture.FutureDate();
                var f = new EventUpdaterFixture(Db);

                f.ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns(new ValidEvent {NumberOfCyclesAllowed = 99});

                var result = f.Subject.AddOrUpdateDueDateEvent(@case, -1, newDate, 2);

                Assert.Equal(1, @case.CaseEvents.Count);
                Assert.Equal(2, @case.CaseEvents.First().Cycle);
                Assert.Equal(-1, @case.CaseEvents.First().EventNo);
                Assert.Equal(newDate, @case.CaseEvents.First().EventDueDate);
                Assert.IsType<PoliceCaseEvent>(result);
            }
        }

        public class EventUpdaterFixture : IFixture<IEventUpdater>
        {
            public EventUpdaterFixture(InMemoryDbContext db)
            {
                ValidEventResolver = Substitute.For<IValidEventResolver>();

                Today = Fixture.Today;

                Subject = new EventUpdater(db, ValidEventResolver, Today);
            }

            public IValidEventResolver ValidEventResolver { get; set; }

            public Func<DateTime> Today { get; set; }
            public IEventUpdater Subject { get; }
        }
    }
}