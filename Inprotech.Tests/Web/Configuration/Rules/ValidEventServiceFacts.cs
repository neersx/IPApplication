using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class ValidEventServiceFacts
    {
        public class GetEventsUsedByCasesMethod : FactBase
        {
            [Fact]
            public void ReturnsEventsUsedByCasesInDisplaySequence()
            {
                var criteriaId = 1;
                var eventId1 = 1;
                var eventId2 = 2;

                var case1 = new CaseBuilder().BuildWithId(1).In(Db);
                new CaseEvent(1, eventId1, 1).In(Db);
                new CaseEvent(1, eventId2, 1).In(Db);
                var criteria = new CriteriaBuilder {Id = criteriaId}.Build().In(Db);
                new OpenActionBuilder(Db) { Criteria = criteria, Case = case1}.Build().In(Db);

                var validEvent1 = new ValidEvent(criteriaId, eventId1) {DisplaySequence = 2}.In(Db);
                var validEvent2 = new ValidEvent(criteriaId, eventId2) {DisplaySequence = 1}.In(Db);

                var f = new ValidEventServiceFixture(Db);
                var r = f.Subject.GetEventsUsedByCases(criteriaId, new[] {eventId1, eventId2}).ToArray();

                Assert.Equal(validEvent2, r.First());
                Assert.Equal(validEvent1, r.Last());
            }

            [Fact]
            public void ShouldNotReturnEventsIfNotUsedByAnyCasesForSameCriteria()
            {
                var criteriaId = 1;
                var eventId = 2;

                new ValidEvent(criteriaId, eventId).In(Db);
                var case1 = new CaseBuilder().BuildWithId(2).In(Db);
                new CaseEvent(1, eventId, 1).In(Db);
                var criteria = new CriteriaBuilder {Id = criteriaId}.Build().In(Db);
                new OpenActionBuilder(Db) { Criteria = criteria, Case = case1}.Build().In(Db);

                var f = new ValidEventServiceFixture(Db);
                var r = f.Subject.GetEventsUsedByCases(criteriaId, new[] {eventId});

                Assert.False(r.Any());
            }

            [Fact]
            public void ShouldNotReturnEventsIfNotUsedByAnyCases()
            {
                var criteriaId = 1;
                var eventId = 2;

                new ValidEvent(criteriaId, eventId).In(Db);

                var f = new ValidEventServiceFixture(Db);
                var r = f.Subject.GetEventsUsedByCases(criteriaId, new[] {eventId});

                Assert.False(r.Any());
            }
        }

        public class AddEventMethod : FactBase
        {
            [Fact]
            public void AddsEventToInheritedChildren()
            {
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var f = new ValidEventServiceFixture(Db);

                var childCriteria = f.AddChildCriteriaFor(criteria);

                var eventToAdd = new EventBuilder {Importance = new ImportanceBuilder().Build().In(Db)}.Build().In(Db);

                f.Subject.AddEvent(criteria.Id, eventToAdd.Id, null, true);

                var eventsAdded = Db.Set<ValidEvent>();

                Assert.Equal(3, eventsAdded.Count());
                Assert.NotNull(eventsAdded.SingleOrDefault(e => e.CriteriaId == criteria.Id));
                Assert.NotNull(eventsAdded.SingleOrDefault(e => e.CriteriaId == childCriteria[0].Id));
                Assert.NotNull(eventsAdded.SingleOrDefault(e => e.CriteriaId == childCriteria[1].Id));
            }

            [Fact]
            public void AddsEventToInheritedChildrenAfterSelectedEventIfExists()
            {
                var f = new ValidEventServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var childCriterias = f.AddChildCriteriaFor(criteria);
                var childCriteriaWithSelectedEvent = childCriterias[0];
                var childCriteriaWithoutSelectedEvent = childCriterias[1];

                var selectedValidEvent = new ValidEventBuilder {Criteria = criteria, DisplaySequence = 0}.Build().In(Db);

                criteria.ValidEvents.Add(selectedValidEvent);
                childCriteriaWithSelectedEvent.ValidEvents.Add(new ValidEventBuilder {Criteria = childCriteriaWithSelectedEvent, Event = selectedValidEvent.Event, DisplaySequence = 0}.Build().In(Db));
                childCriteriaWithSelectedEvent.ValidEvents.Add(new ValidEventBuilder {Criteria = childCriteriaWithSelectedEvent, DisplaySequence = 1}.Build().In(Db));
                childCriteriaWithoutSelectedEvent.ValidEvents.Add(new ValidEventBuilder {Criteria = childCriteriaWithoutSelectedEvent, DisplaySequence = 0}.Build().In(Db));
                childCriteriaWithoutSelectedEvent.ValidEvents.Add(new ValidEventBuilder {Criteria = childCriteriaWithoutSelectedEvent, DisplaySequence = 1}.Build().In(Db));

                var eventToAdd = new EventBuilder {Importance = new ImportanceBuilder().Build().In(Db)}.Build().In(Db);

                f.Subject.AddEvent(criteria.Id, eventToAdd.Id, selectedValidEvent.EventId, true);

                var childWithSelected = Db.Set<ValidEvent>().Where(e => e.CriteriaId == childCriteriaWithSelectedEvent.Id);
                var selectedSequence = childWithSelected.Single(e => e.EventId == selectedValidEvent.EventId).DisplaySequence;
                var addedSequence = childWithSelected.Single(e => e.EventId == eventToAdd.Id).DisplaySequence;
                var childWithoutSelected = Db.Set<ValidEvent>().Where(ve => ve.CriteriaId == childCriteriaWithoutSelectedEvent.Id).OrderBy(ve => ve.DisplaySequence.GetValueOrDefault()).ToArray();

                Assert.Equal(selectedSequence + 1, addedSequence);
                Assert.Equal(3, childWithSelected.Select(e => e.DisplaySequence).Distinct().Count());
                Assert.Equal(eventToAdd.Id, childWithoutSelected.Last().EventId);
            }

            [Fact]
            public void AddsNewEventAfterSelectedEventAndIncrementsSequences()
            {
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var selectedValidEvent = new ValidEventBuilder {Criteria = criteria, DisplaySequence = 0}.Build().In(Db);
                var validEvent2 = new ValidEventBuilder {Criteria = criteria, DisplaySequence = 1}.Build().In(Db);
                var validEvent3 = new ValidEventBuilder {Criteria = criteria, DisplaySequence = 2}.Build().In(Db);
                criteria.ValidEvents.Add(selectedValidEvent);
                criteria.ValidEvents.Add(validEvent2);
                criteria.ValidEvents.Add(validEvent3);

                var importance = new ImportanceBuilder().Build().In(Db);
                var eventToAdd = new EventBuilder {Importance = importance}.Build().In(Db);

                var f = new ValidEventServiceFixture(Db);

                f.Subject.AddEvent(criteria.Id, eventToAdd.Id, selectedValidEvent.EventId, true);

                var events = Db.Set<ValidEvent>().Where(ve => ve.CriteriaId == criteria.Id).OrderBy(ve => ve.DisplaySequence).ToArray();

                Assert.Equal(selectedValidEvent, events[0]);
                Assert.Equal(eventToAdd.Id, events[1].EventId);
                Assert.Equal(validEvent2, events[2]);
                Assert.Equal(validEvent3, events[3]);

                Assert.Equal(0, events[0].DisplaySequence.GetValueOrDefault());
                Assert.Equal(1, events[1].DisplaySequence.GetValueOrDefault());
                Assert.Equal(2, events[2].DisplaySequence.GetValueOrDefault());
                Assert.Equal(3, events[3].DisplaySequence.GetValueOrDefault());

                Assert.Equal(4, events.Select(e => e.DisplaySequence).Distinct().Count());
            }

            [Fact]
            public void AddsNewEventAndReturnsEventDetails()
            {
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var validEvent = new ValidEventBuilder {Criteria = criteria, DisplaySequence = 1}.Build().In(Db);
                criteria.ValidEvents.Add(validEvent);

                var importance = new ImportanceBuilder().Build().In(Db);
                var eventToAdd = new EventBuilder {Importance = importance}.Build().In(Db);

                var f = new ValidEventServiceFixture(Db);
                var result = f.Subject.AddEvent(criteria.Id, eventToAdd.Id, null, true);

                var added = Db.Set<ValidEvent>().SingleOrDefault(ve => ve.CriteriaId == criteria.Id && ve.EventId == eventToAdd.Id);

                Assert.Equal(validEvent.DisplaySequence + 1, added.DisplaySequence);
                Assert.Equal(eventToAdd.Description, added.Description);
                Assert.Equal(eventToAdd.ImportanceLevel, added.ImportanceLevel);
                Assert.Equal(eventToAdd.NumberOfCyclesAllowed, added.NumberOfCyclesAllowed);

                Assert.Equal(eventToAdd.Description, result.Description);
                Assert.Equal(added.DisplaySequence, result.DisplaySequence);
                Assert.Equal(added.Importance.Description, result.Importance.Description);
                Assert.Equal(eventToAdd.ImportanceLevel, result.ImportanceLevel);
                Assert.Equal(eventToAdd.NumberOfCyclesAllowed, result.NumberOfCyclesAllowed);

                Assert.Equal(eventToAdd.RecalcEventDate, result.RecalcEventDate);
                Assert.Equal(eventToAdd.SuppressCalculation, result.SuppressDueDateCalculation);
            }

            [Fact]
            public void DoesNotAddEventToInheritedChildrenWhenNoInherit()
            {
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var f = new ValidEventServiceFixture(Db);
                var childCriteria = f.AddChildCriteriaFor(criteria);

                var eventToAdd = new EventBuilder {Importance = new ImportanceBuilder().Build().In(Db)}.Build().In(Db);

                f.Subject.AddEvent(criteria.Id, eventToAdd.Id, null, false);

                var eventsAdded = Db.Set<ValidEvent>();

                Assert.Equal(1, eventsAdded.Count());
                Assert.NotNull(eventsAdded.SingleOrDefault(e => e.CriteriaId == criteria.Id));
                Assert.Null(eventsAdded.SingleOrDefault(e => e.CriteriaId == childCriteria[0].Id));
                Assert.Null(eventsAdded.SingleOrDefault(e => e.CriteriaId == childCriteria[1].Id));
            }

            [Fact]
            public void DoesNotAddExistingEvent()
            {
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var f = new ValidEventServiceFixture(Db);
                var validEvent = new ValidEventBuilder {Criteria = criteria}.Build().In(Db);
                criteria.ValidEvents.Add(validEvent);

                Assert.Throws<Exception>(() => f.Subject.AddEvent(criteria.Id, validEvent.EventId, null, false));
            }
        }

        public class DeleteEventsMethod : FactBase
        {
            [Fact]
            public void ShouldBreakInheritanceForChildEvents()
            {
                var criteriaId = 1;
                var childCriteriaId = 2;
                var eventId = 1;

                new Inherits(childCriteriaId, criteriaId).In(Db);

                var validEvt = new ValidEvent(childCriteriaId, eventId) {Inherited = 1}.In(Db);
                var f = new ValidEventServiceFixture(Db);

                f.Subject.DeleteEvents(criteriaId, new[] {eventId}, false);

                Assert.Equal(0, validEvt.Inherited.Value);
            }

            [Fact]
            public void ShouldDeleteInheritedEvents()
            {
                var criteriaId = 1;
                var childCriteriaId = 2;
                var eventId = 1;
                var f = new ValidEventServiceFixture(Db);

                new ValidEvent(criteriaId, eventId).In(Db);
                new ValidEvent(childCriteriaId, eventId).In(Db);

                f.Inheritance.GetDescendantsWithInheritedEvent(criteriaId, eventId).Returns(new[] {childCriteriaId});

                Assert.True(Db.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == eventId));

                f.Subject.DeleteEvents(criteriaId, new[] {eventId}, true);

                Assert.False(Db.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == eventId));
            }

            [Fact]
            public void ShouldDeleteParentEvent()
            {
                var criteriaId = 1;
                var eventId = 1;
                var f = new ValidEventServiceFixture(Db);

                new ValidEvent(criteriaId, eventId).In(Db);

                Assert.True(Db.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == eventId));

                f.Subject.DeleteEvents(criteriaId, new[] {eventId}, true);

                Assert.False(Db.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == eventId));
            }
        }

        public class ReorderEventsMethod : FactBase
        {
            [Fact]
            public void ShouldMoveAfterTarget()
            {
                var criteriaId = 1;
                var e1 = new ValidEvent(criteriaId, 1) {DisplaySequence = 1}.In(Db);
                var e2 = new ValidEvent(criteriaId, 2) {DisplaySequence = 2}.In(Db);

                var f = new ValidEventServiceFixture(Db);
                f.Subject.ReorderEvents(criteriaId, e1.EventId, e2.EventId, false);

                Assert.True(e2.DisplaySequence < e1.DisplaySequence);
            }

            [Fact]
            public void ShouldMoveBeforeTarget()
            {
                var criteriaId = 1;
                var e1 = new ValidEvent(criteriaId, 1) {DisplaySequence = 1}.In(Db);
                var e2 = new ValidEvent(criteriaId, 2) {DisplaySequence = 2}.In(Db);

                var f = new ValidEventServiceFixture(Db);
                f.Subject.ReorderEvents(criteriaId, e2.EventId, e1.EventId, true);

                Assert.True(e2.DisplaySequence < e1.DisplaySequence);
            }
        }

        public class ReorderDescendantEventsMethod : FactBase
        {
            [Fact]
            public void ShouldDoNothingIfTargetsAreMissing()
            {
                var criteriaId = 1;
                var e1 = new ValidEvent(criteriaId, 1) {DisplaySequence = 1}.In(Db);
                var e2 = new ValidEvent(criteriaId, 2) {DisplaySequence = 2}.In(Db);

                var f = new ValidEventServiceFixture(Db);

                f.Inheritance.GetDescendantsWithEvent(criteriaId, e2.EventId).Returns(new[] {criteriaId});
                f.Subject.ReorderDescendantEvents(criteriaId, e2.EventId, -1, null, -2, false);

                Assert.Equal((short) 1, e1.DisplaySequence);
                Assert.Equal((short) 2, e2.DisplaySequence);

                f.Subject.ReorderDescendantEvents(criteriaId, e2.EventId, -1, -2, null, true);

                Assert.Equal((short) 1, e1.DisplaySequence);
                Assert.Equal((short) 2, e2.DisplaySequence);
            }

            [Fact]
            public void ShouldMoveAfterTarget()
            {
                var criteriaId = 1;
                var e1 = new ValidEvent(criteriaId, 1) {DisplaySequence = 1}.In(Db);
                var e2 = new ValidEvent(criteriaId, 2) {DisplaySequence = 2}.In(Db);

                var f = new ValidEventServiceFixture(Db);

                f.Inheritance.GetDescendantsWithEvent(criteriaId, e1.EventId).Returns(new[] {criteriaId});
                f.Subject.ReorderDescendantEvents(criteriaId, e1.EventId, e2.EventId, null, null, false);

                Assert.True(e2.DisplaySequence < e1.DisplaySequence);
            }

            [Fact]
            public void ShouldMoveBeforeTarget()
            {
                var criteriaId = 1;
                var e1 = new ValidEvent(criteriaId, 1) {DisplaySequence = 1}.In(Db);
                var e2 = new ValidEvent(criteriaId, 2) {DisplaySequence = 2}.In(Db);

                var f = new ValidEventServiceFixture(Db);

                f.Inheritance.GetDescendantsWithEvent(criteriaId, e2.EventId).Returns(new[] {criteriaId});
                f.Subject.ReorderDescendantEvents(criteriaId, e2.EventId, e1.EventId, null, null, true);

                Assert.True(e2.DisplaySequence < e1.DisplaySequence);
            }

            [Fact]
            public void ShouldMoveToNextTargetIfTargeIsMissing()
            {
                var criteriaId = 1;
                var e1 = new ValidEvent(criteriaId, 1) {DisplaySequence = 1}.In(Db);
                var e2 = new ValidEvent(criteriaId, 2) {DisplaySequence = 3}.In(Db);

                var f = new ValidEventServiceFixture(Db);

                f.Inheritance.GetDescendantsWithEvent(criteriaId, e2.EventId).Returns(new[] {criteriaId});
                f.Subject.ReorderDescendantEvents(criteriaId, e2.EventId, 3, null, e1.EventId, false);

                Assert.True(e1.DisplaySequence > e2.DisplaySequence);
            }

            [Fact]
            public void ShouldMoveToPreTargetIfTargeIsMissing()
            {
                var criteriaId = 1;
                var e1 = new ValidEvent(criteriaId, 1) {DisplaySequence = 1}.In(Db);
                var e2 = new ValidEvent(criteriaId, 2) {DisplaySequence = 3}.In(Db);

                var f = new ValidEventServiceFixture(Db);

                f.Inheritance.GetDescendantsWithEvent(criteriaId, e1.EventId).Returns(new[] {criteriaId});
                f.Subject.ReorderDescendantEvents(criteriaId, e1.EventId, 3, e2.EventId, null, true);

                Assert.True(e1.DisplaySequence > e2.DisplaySequence);
            }
        }

        public class GetAdjacentEventsMethod : FactBase
        {
            [Theory]
            [InlineData(2, 1, 3)]
            [InlineData(1, null, 2)]
            [InlineData(3, 2, null)]
            public void ShouldGetCorrectAdjacentEvents(int eventId, int? expectedResult1, int? expectedResult2)
            {
                var criteriaId = 123;

                int? prevId;
                int? nextId;

                new ValidEvent(criteriaId, 1) {DisplaySequence = 1}.In(Db);
                new ValidEvent(criteriaId, 2) {DisplaySequence = 2}.In(Db);
                new ValidEvent(criteriaId, 3) {DisplaySequence = 3}.In(Db);

                new ValidEvent(321, 3) {DisplaySequence = 1}.In(Db);

                var f = new ValidEventServiceFixture(Db);
                f.Subject.GetAdjacentEvents(criteriaId, eventId, out prevId, out nextId);

                Assert.Equal(expectedResult1, prevId);
                Assert.Equal(expectedResult2, nextId);
            }
        }

        class ValidEventServiceFixture : IFixture<ValidEventService>
        {
            readonly InMemoryDbContext _db;

            public ValidEventServiceFixture(InMemoryDbContext db)
            {
                _db = db;
                Inheritance = Substitute.For<IInheritance>();
            }

            public IInheritance Inheritance { get; }

            public ValidEventService Subject => new ValidEventService(_db, Inheritance);

            public Criteria[] AddChildCriteriaFor(Criteria criteria)
            {
                var childCriteria = new[]
                {
                    new CriteriaBuilder().Build(),
                    new CriteriaBuilder().Build()
                };

                Inheritance.GetDescendantsWithoutEvent(criteria.Id, Arg.Any<int>()).Returns(childCriteria);

                return childCriteria;
            }
        }
    }
}