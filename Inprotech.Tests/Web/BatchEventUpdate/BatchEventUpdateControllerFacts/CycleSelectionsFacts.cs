using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts
{
    public class CycleSelectionsFacts
    {
        public class DeriveControllingCycleFacts : FactBase
        {
            [Fact]
            public void ReturnsCurrentCycleWithNoEventDatePresent()
            {
                var fixture = new CycleSelectionsFixture(Db);
                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 1
                                                    }.Build());

                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 2
                                                    }.Build());

                var result = fixture.Subject.DeriveControllingCycle(fixture.ExistingCase, 
                                                       fixture.ExistingDataEntryTask, 
                                                       fixture.NextRenewalDateEvent1, 
                                                       false);
                Assert.Equal(1, result);
            }

            [Fact]
            public void ReturnsNextCycle()
            {
                var fixture = new CycleSelectionsFixture(Db);
                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 1
                                                    }.Build());

                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 2
                                                    }.Build());

                var result = fixture.Subject.DeriveControllingCycle(fixture.ExistingCase, 
                                                                    fixture.ExistingDataEntryTask, 
                                                                    fixture.NextRenewalDateEvent1, 
                                                                    true);
                Assert.Equal(3, result);
            }

            [Fact]
            public void ReturnsMaxCycle()
            {
                var fixture = new CycleSelectionsFixture(Db);
                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 1
                                                    }.Build());

                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 2
                                                    }.Build());

                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 3
                                                    }.Build());

                var result = fixture.Subject.DeriveControllingCycle(fixture.ExistingCase, 
                                                                    fixture.ExistingDataEntryTask, 
                                                                    fixture.NextRenewalDateEvent1, 
                                                                    true);
                Assert.Equal(3, result);
            }

            [Fact]
            public void ReturnsCurrentCycleWithEventDatePresent()
            {
                var fixture = new CycleSelectionsFixture(Db);
                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 1
                                                    }.AsEventOccurred(Fixture.PastDate()).Build());

                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 2
                                                    }.Build());

                var result = fixture.Subject.DeriveControllingCycle(fixture.ExistingCase, 
                                                                    fixture.ExistingDataEntryTask, 
                                                                    fixture.NextRenewalDateEvent1, 
                                                                    false);
                Assert.Equal(2, result);
            }
        }

        public class IsRequiredFacts : FactBase
        {
            [Fact]
            public void ReturnTrueWhenEventsAreCyclic()
            {
                var fixture = new CycleSelectionsFixture(Db);
                fixture.ExistingCase.CaseEvents.Add(
                                                    new CaseEventBuilder
                                                    {
                                                        EventNo = fixture.NextRenewalDateEvent.Id,
                                                        Cycle = 1
                                                    }.Build());

                var result = fixture.Subject.IsRequired(fixture.ExistingDataEntryTask, fixture.ExistingCase);

                Assert.True(result);
            }

            [Fact]
            public void ReturnFalseWhenNoCaseEventPresent()
            {
                var fixture = new CycleSelectionsFixture(Db);

                var result = fixture.Subject.IsRequired(fixture.ExistingDataEntryTask, fixture.ExistingCase);

                Assert.False(result);
            }
        }

        public class GetMaxCycle : FactBase
        {
            [Fact]
            public void ReturnMaxCycle()
            {
                var fixture = new CycleSelectionsFixture(Db);

                var result = fixture.Subject.GetMaxCycle(fixture.NextRenewalDateEvent1, fixture.ExistingDataEntryTask);

                Assert.Equal(3, result);
            }

            [Fact]
            public void ThrowsExceptionWhenAvailableEventNotPresent()
            {
                var fixture = new CycleSelectionsFixture(Db);

                Assert.Throws<InvalidOperationException>(() => fixture.Subject.GetMaxCycle(fixture.OtherCyclicEvent1, fixture.ExistingDataEntryTask));
            }
        }

        public class IsCyclicalFor : FactBase
        {
            [Fact]
            public void ReturnsFalseWhenNonCyclicEventsPassed()
            {
                var fixture = new CycleSelectionsFixture(Db);
                Assert.False(fixture.Subject.IsCyclicalFor(fixture.OtherNonCyclicEvent1, fixture.ExistingDataEntryTask));
            }

            [Fact]
            public void ReturnsTrueWhenCyclicEventsPassed()
            {
                var fixture = new CycleSelectionsFixture(Db);
                Assert.True(fixture.Subject.IsCyclicalFor(fixture.NextRenewalDateEvent1, fixture.ExistingDataEntryTask));
            }
        }

        public class CycleSelectionsFixture : IFixture<CycleSelection>
        {
            public CycleSelectionsFixture(InMemoryDbContext db)
            {
                ExistingCase = new CaseBuilder().Build().In(db);
                ExistingOpenAction = OpenActionBuilder.ForCaseAsValid(db, ExistingCase).Build();
                ExistingDataEntryTask = DataEntryTaskBuilder.ForCriteria(ExistingOpenAction.Criteria).Build().In(db);
                
                NextRenewalDateEvent = EventBuilder.ForCyclicEvent(3).Build().In(db);

                OtherCyclicEvent = EventBuilder.ForCyclicEvent(2).Build().In(db);

                OtherNonCyclicEvent = EventBuilder.ForNonCyclicEvent().Build().In(db);

                NextRenewalDateEvent1 = new AvailableEventBuilder
                {
                    DataEntryTask = ExistingDataEntryTask,
                    Event = NextRenewalDateEvent,
                    EventAttribute = EntryAttribute.DefaultToSystemDate,
                    DisplaySequence = 0
                }.Build().In(db);
                ExistingDataEntryTask.AvailableEvents.Add(NextRenewalDateEvent1);

                OtherCyclicEvent1 = new AvailableEventBuilder
                {
                    DataEntryTask = ExistingDataEntryTask,
                    Event = OtherCyclicEvent,
                    EventAttribute = EntryAttribute.DefaultToSystemDate,
                    DisplaySequence = 1
                }.Build().In(db);
                
                OtherNonCyclicEvent1 = new AvailableEventBuilder
                {
                    DataEntryTask = ExistingDataEntryTask,
                    Event = OtherNonCyclicEvent,
                    EventAttribute = EntryAttribute.DefaultToSystemDate,
                    DisplaySequence = 2
                }.Build().In(db);
                ExistingDataEntryTask.AvailableEvents.Add(OtherNonCyclicEvent1);
                
                ExistingOpenAction.Criteria.DataEntryTasks.Add(ExistingDataEntryTask);
                ExistingCase.OpenActions.Add(ExistingOpenAction);

                ExistingDataEntryTask.Criteria.ValidEvents.Add(new ValidEventBuilder
                                                                       {
                                                                           Criteria = ExistingDataEntryTask.Criteria,
                                                                           Event = NextRenewalDateEvent,
                                                                           NumberOfCyclesAllowed = 3
                                                                       }.Build().In(db));
                Subject = new CycleSelection();
            }

            public CycleSelection Subject { get; }

            public OpenAction ExistingOpenAction { get; }

            public DataEntryTask ExistingDataEntryTask { get; }
            public Event NextRenewalDateEvent { get; }
            protected Event OtherNonCyclicEvent { get; }
            public Event OtherCyclicEvent { get; }

            public AvailableEvent NextRenewalDateEvent1 { get; }
            public AvailableEvent OtherNonCyclicEvent1 { get; }
            public AvailableEvent OtherCyclicEvent1 { get; }

            public Case ExistingCase { get; set; }
        }
        
    }
}
