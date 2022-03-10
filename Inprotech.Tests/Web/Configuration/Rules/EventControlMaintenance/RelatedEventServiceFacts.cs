using System;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EventControlMaintenance
{
    public class RelatedEventServiceFacts
    {
        public class GetInheritRelatedEventsDeltaMethod
        {
            [Fact]
            public void BreaksInheritanceAndDoesNotUpdateIfItWillResultInADuplicate()
            {
                var f = new RelatedEventServiceFixture();
                var validEvent = f.SetupValidEvent();

                var existingEventId = Fixture.Integer();
                var updateToEventId = Fixture.Integer();

                // try and update this
                var inheritedRule = new RelatedEventRuleBuilder().AsSatisfyingEvent().For(validEvent).Build();
                inheritedRule.IsInherited = true;
                inheritedRule.RelatedEventId = existingEventId;
                inheritedRule.Sequence = 0;
                validEvent.RelatedEvents.Add(inheritedRule);

                // to be a duplicate of one that already exists
                var orphanRule = new RelatedEventRuleBuilder().AsSatisfyingEvent().For(validEvent).Build();
                orphanRule.IsInherited = false;
                orphanRule.RelatedEventId = updateToEventId;
                orphanRule.Sequence = 1;
                orphanRule.RelativeCycleId = 1;
                validEvent.RelatedEvents.Add(orphanRule);

                var fieldsToUpdateDelta = new Delta<int>();
                fieldsToUpdateDelta.Updated.Add(inheritedRule.HashKey());
                var updatedSatisfyingEvent = new SatisfyingEventSaveModelBuilder().For(validEvent).Build();
                updatedSatisfyingEvent.OriginalHashKey = inheritedRule.HashKey();
                updatedSatisfyingEvent.OriginalRelatedEventId = inheritedRule.RelatedEventId.Value;
                updatedSatisfyingEvent.SatisfyingEventId = orphanRule.RelatedEventId;
                updatedSatisfyingEvent.RelativeCycleId = 1;
                var saveModelDelta = new Delta<RelatedEventRuleSaveModel>();
                saveModelDelta.Updated.Add(updatedSatisfyingEvent);

                var result = f.Subject.GetInheritRelatedEventsDelta(fieldsToUpdateDelta, validEvent.RelatedEvents, saveModelDelta);

                Assert.Empty(result.Updated);
                Assert.False(validEvent.RelatedEvents.Single(_ => _.Sequence == 0).IsInherited);
            }

            [Fact]
            public void ReturnsEventsMatchingOnHashKey()
            {
                var f = new RelatedEventServiceFixture();
                var validEvent = f.SetupValidEvent();
                var added = new RelatedEventRuleBuilder().AsEventToClear().For(validEvent).Build();
                var updated = new SatisfyingEventSaveModelBuilder {Inherited = 1}.AsEventToClear().For(validEvent).Build();
                var deleted = new SatisfyingEventSaveModelBuilder {Inherited = 1}.AsEventToClear().For(validEvent).Build();
                validEvent.RelatedEvents.AddRange(new[] {updated, deleted});

                var newValuesDelta = new Delta<RelatedEventRuleSaveModel>();

                var fieldsToUpdateDelta = new Delta<int>();
                fieldsToUpdateDelta.Added.Add(added.HashKey());
                fieldsToUpdateDelta.Updated.Add(updated.HashKey());
                fieldsToUpdateDelta.Deleted.Add(deleted.HashKey());

                // should not inherit these since they don't exist in ValidEvent
                fieldsToUpdateDelta.Updated.Add(Fixture.Integer());
                fieldsToUpdateDelta.Deleted.Add(Fixture.Integer());

                var result = f.Subject.GetInheritRelatedEventsDelta(fieldsToUpdateDelta, validEvent.RelatedEvents, newValuesDelta);
                Assert.Equal(added.HashKey(), result.Added.Single());
                Assert.Equal(updated.HashKey(), result.Updated.Single());
                Assert.Equal(deleted.HashKey(), result.Deleted.Single());
            }

            [Fact]
            public void PassOnOnlyApplicableAddedFieldsForInheritance()
            {
                var f = new RelatedEventServiceFixture();
                var validEvent = f.SetupValidEvent();
          
                var saveModelDelta = new Delta<RelatedEventRuleSaveModel>();
                var relatedEvent1 = new RelatedEventSaveModelBuilder().For(validEvent).Build();
                var relatedEvent2 = new RelatedEventSaveModelBuilder().For(validEvent).Build();
                saveModelDelta.Added.Add(relatedEvent1);
                saveModelDelta.Added.Add(relatedEvent2);

                var fieldsToUpdate = new Delta<int>();
                fieldsToUpdate.Added.Add(relatedEvent1.HashKey());
                var result = f.Subject.GetInheritRelatedEventsDelta(fieldsToUpdate, validEvent.RelatedEvents, saveModelDelta);

                Assert.NotNull(result.Added);
                Assert.True(result.Added.Contains(relatedEvent1.HashKey()));
            }

            [Fact]
            public void PassOnOnlyApplicableUpdatedFieldsForInheritance()
            {
                var f = new RelatedEventServiceFixture();
                var validEvent = f.SetupValidEvent();
          
                var saveModelDelta = new Delta<RelatedEventRuleSaveModel>();
                var relatedEvent1 = new RelatedEventSaveModelBuilder{Inherited = 1}.For(validEvent).Build();
                relatedEvent1.OriginalHashKey = relatedEvent1.HashKey();
                relatedEvent1.OriginalRelatedEventId = relatedEvent1.RelatedEventId ?? 0;
                validEvent.RelatedEvents.Add(relatedEvent1);
                var relatedEvent2 = new RelatedEventSaveModelBuilder{Inherited = 1}.For(validEvent).Build();
                relatedEvent2.OriginalHashKey = relatedEvent2.HashKey();
                relatedEvent2.OriginalRelatedEventId = relatedEvent2.RelatedEventId ?? 0;
                validEvent.RelatedEvents.Add(relatedEvent1);
                saveModelDelta.Updated.Add(relatedEvent1);
                saveModelDelta.Updated.Add(relatedEvent2);

                var fieldsToUpdate = new Delta<int>();
                fieldsToUpdate.Updated.Add(relatedEvent1.OriginalHashKey);
                var result = f.Subject.GetInheritRelatedEventsDelta(fieldsToUpdate, validEvent.RelatedEvents, saveModelDelta);

                Assert.NotNull(result.Updated);
                Assert.True(result.Updated.Contains(relatedEvent1.OriginalHashKey));
            }
        }

        public class AddMethod
        {
            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public void AddsOrInhertsRelatedEventRules(bool inherit)
            {
                var f = new RelatedEventServiceFixture();
                var eventRule = f.SetupValidEvent();

                var newSatisfyingEventRule = new SatisfyingEventSaveModelBuilder().For(eventRule).Build();
                var newEventToClearRule = new RelatedEventSaveModelBuilder().AsEventToClear().For(eventRule).Build();
                var newEventToUpdateRule = new RelatedEventSaveModelBuilder().AsEventToUpdate().For(eventRule).Build();

                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Added.AddRange(new[] {newSatisfyingEventRule, newEventToClearRule, newEventToUpdateRule});

                var originatingCriteriaId = inherit ? Fixture.Integer() : eventRule.CriteriaId;

                f.Subject.ApplyRelatedEventChanges(originatingCriteriaId, eventRule, delta, false);

                Assert.Equal(3, eventRule.RelatedEvents.Count);
                Assert.True(eventRule.RelatedEvents.All(_ => _.IsInherited == inherit));
                Assert.Single(eventRule.RelatedEvents.WhereIsSatisfyingEvent());
                Assert.Single(eventRule.RelatedEvents.WhereEventsToClear());
                Assert.Single(eventRule.RelatedEvents.WhereEventsToUpdate());
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public void UpdatesOrInheritsRelatedEventRules(bool inherit)
            {
                var f = new RelatedEventServiceFixture();
                var eventRule = f.SetupValidEvent();
                var originatingCriteriaId = inherit ? Fixture.Integer() : eventRule.CriteriaId;

                var existingSatisfyingEvent = new SatisfyingEventSaveModelBuilder().For(eventRule).Build();
                var existingEventToClearRule = new RelatedEventSaveModelBuilder().AsEventToClear().For(eventRule).Build();
                var existingEventToUpdateRule = new RelatedEventSaveModelBuilder().AsEventToUpdate().For(eventRule).Build();
                existingSatisfyingEvent.IsInherited = inherit;
                existingEventToClearRule.IsInherited = inherit;
                existingEventToUpdateRule.IsInherited = inherit;

                eventRule.RelatedEvents.AddRange(new[] {existingSatisfyingEvent, existingEventToClearRule, existingEventToUpdateRule});

                var updatedSatisfyingEvent = new RelatedEventRuleSaveModel();
                updatedSatisfyingEvent.CopyFrom(existingSatisfyingEvent);
                updatedSatisfyingEvent.OriginalHashKey = existingSatisfyingEvent.HashKey();
                updatedSatisfyingEvent.RelativeCycle = Fixture.Short(); // change something

                var updatedEventToClearRule = new RelatedEventRuleSaveModel();
                updatedEventToClearRule.CopyFrom(existingEventToClearRule);
                updatedEventToClearRule.OriginalHashKey = existingEventToClearRule.HashKey();
                updatedEventToClearRule.RelativeCycle = Fixture.Short(); // change something

                var updatedEventToUpdateRule = new RelatedEventRuleSaveModel();
                updatedEventToUpdateRule.CopyFrom(existingEventToUpdateRule);
                updatedEventToUpdateRule.OriginalHashKey = existingEventToUpdateRule.HashKey();
                updatedEventToUpdateRule.RelativeCycle = Fixture.Short(); // change something

                var seDelta = new Delta<RelatedEventRuleSaveModel>();
                seDelta.Updated.Add(updatedSatisfyingEvent);

                f.Subject.ApplyRelatedEventChanges(originatingCriteriaId, eventRule, seDelta, false);
                var updatedRule = eventRule.RelatedEvents.WhereIsSatisfyingEvent().Single();
                Assert.Equal(updatedSatisfyingEvent.RelativeCycleId, updatedRule.RelativeCycleId);
                Assert.Equal(inherit, updatedRule.IsInherited);

                var etcDelta = new Delta<RelatedEventRuleSaveModel>();
                etcDelta.Updated.Add(updatedEventToClearRule);

                f.Subject.ApplyRelatedEventChanges(originatingCriteriaId, eventRule, etcDelta, false);
                updatedRule = eventRule.RelatedEvents.WhereEventsToClear().Single();
                Assert.Equal(updatedEventToClearRule.RelativeCycleId, updatedRule.RelativeCycleId);
                Assert.Equal(inherit, updatedRule.IsInherited);

                var etuDelta = new Delta<RelatedEventRuleSaveModel>();
                etuDelta.Updated.Add(updatedEventToUpdateRule);

                f.Subject.ApplyRelatedEventChanges(originatingCriteriaId, eventRule, etuDelta, false);
                updatedRule = eventRule.RelatedEvents.WhereEventsToUpdate().Single();
                Assert.Equal(updatedEventToUpdateRule.RelativeCycleId, updatedRule.RelativeCycleId);
                Assert.Equal(inherit, updatedRule.IsInherited);
            }

            [Fact]
            public void AddsNewEventToClearRowForMultiUseRelatedEvent()
            {
                var f = new RelatedEventServiceFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();

                var existingMultiUseRow = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1, IsClearEvent = true}.For(eventRule).Build();
                existingMultiUseRow.IsSatisfyingEvent = true;
                existingMultiUseRow.IsClearDue = true;
                existingMultiUseRow.ClearEventOnDueChange = true;
                existingMultiUseRow.ClearDueOnDueChange = true;
                existingMultiUseRow.ValidEvent = eventRule;
                eventRule.RelatedEvents.Add(existingMultiUseRow);

                var editedEventToClear = new RelatedEventSaveModelBuilder().For(eventRule).Build();
                editedEventToClear.OriginalHashKey = existingMultiUseRow.HashKey();
                editedEventToClear.IsClearEvent = false;
                editedEventToClear.IsClearDue = true;
                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Updated.Add(editedEventToClear);

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false);

                var updatedRule = eventRule.RelatedEvents.Single(_ => _.Sequence == sequence);
                Assert.True(updatedRule.IsSatisfyingEvent);
                Assert.False(updatedRule.IsClearEvent);
                Assert.False(updatedRule.IsClearDue);
                Assert.False(updatedRule.ClearEventOnDueChange.GetValueOrDefault());
                Assert.False(updatedRule.ClearDueOnDueChange.GetValueOrDefault());

                var addedEventToClearRule = eventRule.RelatedEvents.Except(new[] {updatedRule}).Single();
                Assert.NotEqual(sequence, addedEventToClearRule.Sequence);
                Assert.False(addedEventToClearRule.IsSatisfyingEvent);
                Assert.Equal(editedEventToClear.RelatedEventId, addedEventToClearRule.RelatedEventId);
                Assert.Equal(editedEventToClear.RelativeCycleId, addedEventToClearRule.RelativeCycleId);
                Assert.False(addedEventToClearRule.IsClearEvent);
                Assert.True(addedEventToClearRule.IsClearDue);
            }

            [Fact]
            public void AddsNewEventToUpdateRowForMultiUseRelatedEvent()
            {
                var f = new RelatedEventServiceFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();

                var existingMultiUseRow = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1, IsUpdateEvent = true, IsSatisfyingEvent = true}.For(eventRule).Build();
                existingMultiUseRow.DateAdjustmentId = "A";
                existingMultiUseRow.ValidEvent = eventRule;
                eventRule.RelatedEvents.Add(existingMultiUseRow);

                var editedEventToUpdate = new RelatedEventSaveModelBuilder().For(eventRule).Build();
                editedEventToUpdate.OriginalHashKey = existingMultiUseRow.HashKey();
                editedEventToUpdate.IsUpdateEvent = true;
                editedEventToUpdate.DateAdjustmentId = "B";
                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Updated.Add(editedEventToUpdate);

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false);

                var updatedRule = eventRule.RelatedEvents.Single(_ => _.Sequence == sequence);
                Assert.True(updatedRule.IsSatisfyingEvent);
                Assert.False(updatedRule.IsUpdateEvent);
                Assert.Null(updatedRule.DateAdjustmentId);

                var addedEventToUpdateRule = eventRule.RelatedEvents.Except(new[] {updatedRule}).Single();
                Assert.NotEqual(sequence, addedEventToUpdateRule.Sequence);
                Assert.False(addedEventToUpdateRule.IsSatisfyingEvent);
                Assert.Equal(editedEventToUpdate.DateAdjustmentId, addedEventToUpdateRule.DateAdjustmentId);
                Assert.True(addedEventToUpdateRule.IsUpdateEvent);
            }

            [Fact]
            public void AddsNewSatisfyingEventRowForMultiUseRelatedEvent()
            {
                var f = new RelatedEventServiceFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();

                var existingMultiUseRow = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1}.AsSatisfyingEvent().For(eventRule).Build();
                existingMultiUseRow.ClearEvent = 1;
                existingMultiUseRow.ValidEvent = eventRule;
                eventRule.RelatedEvents.Add(existingMultiUseRow);

                var editedSatisfyingEvent = new SatisfyingEventSaveModelBuilder().For(eventRule).Build();
                editedSatisfyingEvent.OriginalHashKey = existingMultiUseRow.HashKey();
                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Updated.Add(editedSatisfyingEvent);

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false);

                var updatedRule = eventRule.RelatedEvents.Single(_ => _.Sequence == sequence);
                Assert.False(updatedRule.IsSatisfyingEvent);
                var newSatisfyingRule = eventRule.RelatedEvents.Except(new[] {updatedRule}).Single();
                Assert.NotEqual(sequence, newSatisfyingRule.Sequence);
                Assert.True(newSatisfyingRule.IsSatisfyingEvent);
                Assert.Equal(editedSatisfyingEvent.RelatedEventId, newSatisfyingRule.RelatedEventId);
                Assert.Equal(editedSatisfyingEvent.RelativeCycleId, newSatisfyingRule.RelativeCycleId);
            }

            [Fact]
            public void DeletesEventsToClear()
            {
                var f = new RelatedEventServiceFixture();
                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();

                var existingEventToClearToDelete = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1}.AsEventToClear().For(eventRule).Build();
                existingEventToClearToDelete.ValidEvent = eventRule;
                eventRule.RelatedEvents.Add(existingEventToClearToDelete);

                var existingEventToClear = new RelatedEventRuleBuilder {Sequence = Fixture.Short(), Inherited = 1}.AsEventToClear().For(eventRule).Build();
                eventRule.RelatedEvents.Add(existingEventToClear);

                var deletedEventToClear = new RelatedEventSaveModelBuilder().AsEventToClear().For(eventRule).Build();
                deletedEventToClear.OriginalHashKey = existingEventToClearToDelete.HashKey();
                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Deleted.Add(deletedEventToClear);

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false);
                Assert.DoesNotContain(eventRule.RelatedEvents, _ => _.Sequence == existingEventToClearToDelete.Sequence);
                Assert.Contains(eventRule.RelatedEvents, _ => _.Sequence == existingEventToClear.Sequence);
            }

            [Fact]
            public void DeletesEventsToUpdate()
            {
                var f = new RelatedEventServiceFixture();
                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();

                var existingEventToUpdateToDelete = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1}.AsEventToUpdate().For(eventRule).Build();
                existingEventToUpdateToDelete.ValidEvent = eventRule;
                eventRule.RelatedEvents.Add(existingEventToUpdateToDelete);

                var existingEventToDelete = new RelatedEventRuleBuilder {Sequence = Fixture.Short(), Inherited = 1}.AsEventToUpdate().For(eventRule).Build();
                eventRule.RelatedEvents.Add(existingEventToDelete);

                var deletedEventToUpdate = new RelatedEventSaveModelBuilder().AsEventToUpdate().For(eventRule).Build();
                deletedEventToUpdate.OriginalHashKey = existingEventToUpdateToDelete.HashKey();
                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Deleted.Add(deletedEventToUpdate);

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false);
                Assert.DoesNotContain(eventRule.RelatedEvents, _ => _.Sequence == existingEventToUpdateToDelete.Sequence);
                Assert.Contains(eventRule.RelatedEvents, _ => _.Sequence == existingEventToDelete.Sequence);
            }

            [Fact]
            public void DeletesSatisfyingEvents()
            {
                var f = new RelatedEventServiceFixture();
                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();

                var existingSatisfyingEventToDelete = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1}.AsSatisfyingEvent().For(eventRule).Build();
                existingSatisfyingEventToDelete.ValidEvent = eventRule;
                eventRule.RelatedEvents.Add(existingSatisfyingEventToDelete);

                var existingSatisfyingEvent = new RelatedEventRuleBuilder {Sequence = Fixture.Short(), Inherited = 1}.AsSatisfyingEvent().For(eventRule).Build();
                eventRule.RelatedEvents.Add(existingSatisfyingEvent);

                var deletedSatisfyingEvent = new SatisfyingEventSaveModelBuilder().For(eventRule).Build();
                deletedSatisfyingEvent.OriginalHashKey = existingSatisfyingEventToDelete.HashKey();
                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Deleted.Add(deletedSatisfyingEvent);

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false);
                Assert.DoesNotContain(eventRule.RelatedEvents, _ => _.Sequence == existingSatisfyingEventToDelete.Sequence);
                Assert.Contains(eventRule.RelatedEvents, _ => _.Sequence == existingSatisfyingEvent.Sequence);
            }

            [Fact]
            public void HandlesMultipleOperationsThatChangeTheHash()
            {
                var f = new RelatedEventServiceFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();
                var existingRelatedEvent = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1, IsClearEvent = true}.AsSatisfyingEvent().For(eventRule).Build();
                existingRelatedEvent.ValidEvent = eventRule;
                eventRule.RelatedEvents.Add(existingRelatedEvent);

                var updateSatisfyingEvent = new SatisfyingEventSaveModelBuilder().For(eventRule).Build();
                updateSatisfyingEvent.Sequence = sequence;
                updateSatisfyingEvent.RelativeCycle = Fixture.Short();
                updateSatisfyingEvent.OriginalHashKey = existingRelatedEvent.HashKey();
                var updateEventToClear = new RelatedEventSaveModelBuilder().For(eventRule).Build();
                updateEventToClear.Sequence = sequence;
                updateEventToClear.IsClearEvent = false;
                updateEventToClear.IsClearDue = true;
                updateEventToClear.OriginalHashKey = existingRelatedEvent.HashKey();

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, new Delta<RelatedEventRuleSaveModel> {Updated = new[] {updateSatisfyingEvent}}, false);
                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, new Delta<RelatedEventRuleSaveModel> {Updated = new[] {updateEventToClear}}, false);

                var updatedSatisfyingEvent = eventRule.RelatedEvents.WhereIsSatisfyingEvent().Single();
                var updatedEventToClear = eventRule.RelatedEvents.WhereEventsToClear().Single();

                Assert.NotSame(updatedSatisfyingEvent, updatedEventToClear);
                Assert.Equal(updateSatisfyingEvent.RelativeCycleId, updatedSatisfyingEvent.RelativeCycleId);

                Assert.True(updatedEventToClear.IsClearDue);
                Assert.False(updatedEventToClear.IsClearEvent);
            }

            [Fact]
            public void ThrowsErrorWhenAddingDuplicateEventToUpdate()
            {
                var f = new RelatedEventServiceFixture();
                var eventRule = new ValidEventBuilder().Build();
                var newEventToUpdate = new RelatedEventSaveModelBuilder().AsEventToUpdate().For(eventRule).Build();
                eventRule.RelatedEvents.Add(newEventToUpdate);

                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Added.Add(newEventToUpdate);

                var exception = Assert.Throws<InvalidOperationException>(() => f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false));
                Assert.Contains("update event", exception.Message);
            }

            [Fact]
            public void UnflagsEventToClearForDeleteOnMultiUseRule()
            {
                var f = new RelatedEventServiceFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();
                var existingEventToClearToDelete = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1}.AsSatisfyingEvent().For(eventRule).Build();
                existingEventToClearToDelete.ClearDue = 1;
                eventRule.RelatedEvents.Add(existingEventToClearToDelete);

                var deletedEventToClear = new RelatedEventSaveModelBuilder {IsClearEvent = true}.For(eventRule).Build();
                deletedEventToClear.OriginalHashKey = existingEventToClearToDelete.HashKey();

                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Deleted.Add(deletedEventToClear);

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false);
                Assert.False(eventRule.RelatedEvents.Single().IsClearEvent);
                Assert.True(eventRule.RelatedEvents.Single().IsSatisfyingEvent);
            }

            [Fact]
            public void UnflagsEventToUpdateForDeleteOnMultiUseRule()
            {
                var f = new RelatedEventServiceFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();
                var existingEventToUpdateToDelete = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1, IsUpdateEvent = true, IsSatisfyingEvent = true}.For(eventRule).Build();
                existingEventToUpdateToDelete.DateAdjustmentId = "a";
                eventRule.RelatedEvents.Add(existingEventToUpdateToDelete);

                var deletedEventToUpdate = new RelatedEventSaveModelBuilder {IsUpdateEvent = true}.For(eventRule).Build();
                deletedEventToUpdate.OriginalHashKey = existingEventToUpdateToDelete.HashKey();

                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Deleted.Add(deletedEventToUpdate);

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false);
                Assert.False(eventRule.RelatedEvents.Single().IsUpdateEvent);
                Assert.Null(eventRule.RelatedEvents.Single().DateAdjustmentId);
                Assert.True(eventRule.RelatedEvents.Single().IsSatisfyingEvent);
            }

            [Fact]
            public void UnflagsSatisfyingEventForDeleteOnMultiUseRule()
            {
                var f = new RelatedEventServiceFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();

                var existingSatisfyingEventToDelete = new RelatedEventRuleBuilder {Sequence = sequence, Inherited = 1}.AsSatisfyingEvent().For(eventRule).Build();
                existingSatisfyingEventToDelete.ClearDue = 1;
                eventRule.RelatedEvents.Add(existingSatisfyingEventToDelete);

                var deletedSatisfyingEvent = new SatisfyingEventSaveModelBuilder().For(eventRule).Build();
                deletedSatisfyingEvent.OriginalHashKey = existingSatisfyingEventToDelete.HashKey();

                var delta = new Delta<RelatedEventRuleSaveModel>();
                delta.Deleted.Add(deletedSatisfyingEvent);

                f.Subject.ApplyRelatedEventChanges(Fixture.Integer(), eventRule, delta, false);
                Assert.False(eventRule.RelatedEvents.Single().IsSatisfyingEvent);
                Assert.True(eventRule.RelatedEvents.Single().IsClearDue);
            }
        }
    }

    public class RelatedEventServiceFixture : IFixture<RelatedEventService>
    {
        public RelatedEventServiceFixture()
        {
            Subject = new RelatedEventService();
        }

        public RelatedEventService Subject { get; }

        public ValidEvent SetupValidEvent()
        {
            var baseEvent = new Event(Fixture.Integer());
            var criteria = new CriteriaBuilder().Build();
            var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();

            return eventRule;
        }
    }
}