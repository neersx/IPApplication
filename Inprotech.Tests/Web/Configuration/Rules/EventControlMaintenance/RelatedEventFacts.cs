using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EventControlMaintenance
{
    public class RelatedEventFacts
    {
        public class ValidateMethod
        {
            [Fact]
            public void RetrunsErrorsIfMandatoryFieldsMissing()
            {
                var f = new RelatedEventFixture();

                var saveModel = new WorkflowEventControlSaveModel();

                var seSaveModel = new SatisfyingEventSaveModelBuilder().Build();
                seSaveModel.RelatedEventId = null;
                saveModel.SatisfyingEventsDelta.Added.Add(seSaveModel);

                var etuSaveModel = new RelatedEventRuleSaveModel();
                saveModel.EventsToUpdateDelta.Updated.Add(etuSaveModel);

                var etcSaveModel = new RelatedEventRuleSaveModel();
                etcSaveModel.RelatedEventId = Fixture.Integer();
                etcSaveModel.RelativeCycle = Fixture.Short();
                saveModel.EventsToClearDelta.Added.Add(etcSaveModel);

                var result = f.Subject.Validate(saveModel).ToArray();

                Assert.Equal(3, result.Length);
                Assert.Contains("satisfyingEvent", result.Select(_ => _.Topic));
                Assert.Contains("eventToUpdate", result.Select(_ => _.Topic));
                Assert.Contains("eventsToClear", result.Select(_ => _.Topic));
            }

            [Fact]
            public void ReturnsNoErrorsIfAllMandatoryFieldsAreEntered()
            {
                var f = new RelatedEventFixture();

                var saveModel = new WorkflowEventControlSaveModel();

                var seSaveModel = new SatisfyingEventSaveModelBuilder().Build();
                saveModel.SatisfyingEventsDelta.Added.Add(seSaveModel);

                var etuSaveModel = new RelatedEventRuleSaveModel();
                etuSaveModel.CopyFrom(seSaveModel);
                etuSaveModel.SatisfyEvent = 0;
                saveModel.EventsToUpdateDelta.Updated.Add(etuSaveModel);

                var etcSaveModel = new RelatedEventRuleSaveModel();
                etcSaveModel.CopyFrom(etuSaveModel);
                etcSaveModel.ClearDueDateOnDueDateChange = true;
                saveModel.EventsToClearDelta.Added.Add(etcSaveModel);

                var result = f.Subject.Validate(saveModel).ToArray();

                Assert.Empty(result);
            }
        }

        public class SetChildInheritanceDeltaMethod
        {
            [Fact]
            public void SetsDeltaToInherited()
            {
                var f = new RelatedEventFixture();

                var validEvent = f.SetupValidEvent();
                var saveModel = new WorkflowEventControlSaveModel();
                var seDelta = new Delta<int>();
                var etcDelta = new Delta<int>();
                var etuDelta = new Delta<int>();

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.SatisfyingEventsDelta = seDelta;
                fieldsToUpdate.EventsToClearDelta = etcDelta;
                fieldsToUpdate.EventsToUpdateDelta = etuDelta;

                var mockReturnFields = new EventControlFieldsToUpdate();

                f.RelatedEventService.GetInheritRelatedEventsDelta(seDelta, Arg.Any<IEnumerable<RelatedEventRule>>(), saveModel.SatisfyingEventsDelta).Returns(mockReturnFields.SatisfyingEventsDelta);
                f.RelatedEventService.GetInheritRelatedEventsDelta(etcDelta, Arg.Any<IEnumerable<RelatedEventRule>>(), saveModel.EventsToClearDelta).Returns(mockReturnFields.EventsToClearDelta);
                f.RelatedEventService.GetInheritRelatedEventsDelta(etuDelta, Arg.Any<IEnumerable<RelatedEventRule>>(), saveModel.EventsToUpdateDelta).Returns(mockReturnFields.EventsToUpdateDelta);

                f.Subject.SetChildInheritanceDelta(validEvent, saveModel, fieldsToUpdate);

                f.RelatedEventService.Received(1).GetInheritRelatedEventsDelta(seDelta, Arg.Any<IEnumerable<RelatedEventRule>>(), saveModel.SatisfyingEventsDelta);
                f.RelatedEventService.Received(1).GetInheritRelatedEventsDelta(etcDelta, Arg.Any<IEnumerable<RelatedEventRule>>(), saveModel.EventsToClearDelta);
                f.RelatedEventService.Received(1).GetInheritRelatedEventsDelta(etuDelta, Arg.Any<IEnumerable<RelatedEventRule>>(), saveModel.EventsToUpdateDelta);

                Assert.Equal(fieldsToUpdate.SatisfyingEventsDelta, mockReturnFields.SatisfyingEventsDelta);
                Assert.Equal(fieldsToUpdate.EventsToClearDelta, mockReturnFields.EventsToClearDelta);
                Assert.Equal(fieldsToUpdate.EventsToUpdateDelta, mockReturnFields.EventsToUpdateDelta);
            }
        }

        public class ApplyChangesMethod : FactBase
        {
            [Fact]
            public void PassesDeltaToApplyMethod()
            {
                var f = new RelatedEventFixture();

                var validEvent = f.SetupValidEvent();
                var saveModel = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                var mockReturnStandingInstrucionsDelta = new Delta<RelatedEventRuleSaveModel>();
                var mockReturnEventToClearDelta = new Delta<RelatedEventRuleSaveModel>();
                var mockReturnEventToUpdateDelta = new Delta<RelatedEventRuleSaveModel>();

                f.WorkflowEventInheritanceService.GetDelta(saveModel.SatisfyingEventsDelta, fieldsToUpdate.SatisfyingEventsDelta, Arg.Any<Func<RelatedEventRuleSaveModel, int>>(), Arg.Any<Func<RelatedEventRuleSaveModel, int>>()).Returns(mockReturnStandingInstrucionsDelta);
                f.WorkflowEventInheritanceService.GetDelta(saveModel.EventsToClearDelta, fieldsToUpdate.EventsToClearDelta, Arg.Any<Func<RelatedEventRuleSaveModel, int>>(), Arg.Any<Func<RelatedEventRuleSaveModel, int>>()).Returns(mockReturnEventToClearDelta);
                f.WorkflowEventInheritanceService.GetDelta(saveModel.EventsToUpdateDelta, fieldsToUpdate.EventsToUpdateDelta, Arg.Any<Func<RelatedEventRuleSaveModel, int>>(), Arg.Any<Func<RelatedEventRuleSaveModel, int>>()).Returns(mockReturnEventToUpdateDelta);

                f.Subject.ApplyChanges(validEvent, saveModel, fieldsToUpdate);

                f.RelatedEventService.Received(1).ApplyRelatedEventChanges(saveModel.OriginatingCriteriaId, validEvent, mockReturnStandingInstrucionsDelta, false);
                f.RelatedEventService.Received(1).ApplyRelatedEventChanges(saveModel.OriginatingCriteriaId, validEvent, mockReturnEventToClearDelta, false);
                f.RelatedEventService.Received(1).ApplyRelatedEventChanges(saveModel.OriginatingCriteriaId, validEvent, mockReturnEventToUpdateDelta, false);
            }
        }

        public class RemoveInheritanceMethod
        {
            [Fact]
            public void RemovesInheritanceOnAllUpdatedAndDeleted()
            {
                var f = new RelatedEventFixture();

                var validEvent = f.SetupValidEvent();

                var satisfyingEventUpdate = new RelatedEventRuleBuilder {Inherited = 1}.AsSatisfyingEvent().Build();
                var satisfyingEventDelete = new RelatedEventRuleBuilder {Inherited = 1}.AsSatisfyingEvent().Build();
                var eventToClearUpdate = new RelatedEventRuleBuilder {Inherited = 1}.AsEventToClear().Build();
                var eventToClearDelete = new RelatedEventRuleBuilder {Inherited = 1}.AsEventToClear().Build();
                var eventToUpdateUpdate = new RelatedEventRuleBuilder {Inherited = 1}.AsEventToUpdate().Build();
                var eventToUpdateDelete = new RelatedEventRuleBuilder {Inherited = 1}.AsEventToUpdate().Build();
                validEvent.RelatedEvents.AddRange(new[] {satisfyingEventUpdate, satisfyingEventDelete, eventToClearUpdate, eventToClearDelete, eventToUpdateUpdate, eventToUpdateDelete});

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.SatisfyingEventsDelta.Updated.Add(satisfyingEventUpdate.HashKey());
                fieldsToUpdate.SatisfyingEventsDelta.Deleted.Add(satisfyingEventDelete.HashKey());
                fieldsToUpdate.EventsToClearDelta.Updated.Add(eventToClearDelete.HashKey());
                fieldsToUpdate.EventsToClearDelta.Deleted.Add(eventToClearUpdate.HashKey());
                fieldsToUpdate.EventsToUpdateDelta.Updated.Add(eventToUpdateUpdate.HashKey());
                fieldsToUpdate.EventsToUpdateDelta.Deleted.Add(eventToUpdateDelete.HashKey());

                f.Subject.RemoveInheritance(validEvent, fieldsToUpdate);
                Assert.True(validEvent.RelatedEvents.All(_ => _.IsInherited == false));
            }
        }

        public class ResetMethod
        {
            [Fact]
            public void AddsIfNotExisting()
            {
                var f = new RelatedEventFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var satisfyingEventRule = new RelatedEventRuleBuilder().AsSatisfyingEvent().Build();
                var eventToClearRule = new RelatedEventRuleBuilder().AsEventToClear().Build();
                var eventToUpdateRule = new RelatedEventRuleBuilder().AsEventToUpdate().Build();
                parent.RelatedEvents.AddRange(new[] {satisfyingEventRule, eventToClearRule, eventToUpdateRule});

                f.Subject.Reset(newValues, parent, criteria);

                var satisfyingEvent = newValues.SatisfyingEventsDelta.Added.First();
                var eventToClear = newValues.EventsToClearDelta.Added.First();
                var eventToUpdate = newValues.EventsToUpdateDelta.Added.First();

                Assert.Equal(satisfyingEventRule.HashKey(), satisfyingEvent.HashKey());
                Assert.Equal(eventToClearRule.HashKey(), eventToClear.HashKey());
                Assert.Equal(eventToUpdateRule.HashKey(), eventToUpdate.HashKey());

                Assert.Empty(newValues.SatisfyingEventsDelta.Updated);
                Assert.Empty(newValues.SatisfyingEventsDelta.Deleted);

                Assert.Empty(newValues.EventsToClearDelta.Updated);
                Assert.Empty(newValues.EventsToClearDelta.Deleted);

                Assert.Empty(newValues.EventsToUpdateDelta.Updated);
                Assert.Empty(newValues.EventsToUpdateDelta.Deleted);
            }

            [Fact]
            public void DeletesIfNotInParent()
            {
                var f = new RelatedEventFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var satisfyingEventRule = new RelatedEventRuleBuilder().AsSatisfyingEvent().Build();
                var eventToClearRule = new RelatedEventRuleBuilder().AsEventToClear().Build();
                var eventToUpdateRule = new RelatedEventRuleBuilder().AsEventToUpdate().Build();
                criteria.RelatedEvents.AddRange(new[] {satisfyingEventRule, eventToClearRule, eventToUpdateRule});

                f.Subject.Reset(newValues, parent, criteria);

                var satisfyingEvent = newValues.SatisfyingEventsDelta.Deleted.First();
                var eventToClear = newValues.EventsToClearDelta.Deleted.First();
                var eventToUpdate = newValues.EventsToUpdateDelta.Deleted.First();
                Assert.Equal(satisfyingEventRule.HashKey(), satisfyingEvent.OriginalHashKey);
                Assert.Equal(eventToClearRule.HashKey(), eventToClear.OriginalHashKey);
                Assert.Equal(eventToUpdateRule.HashKey(), eventToUpdate.OriginalHashKey);

                Assert.True(satisfyingEvent.IsSatisfyingEvent);
                Assert.True(eventToClear.IsClearEvent);
                Assert.True(eventToUpdate.IsUpdateEvent);

                Assert.Empty(newValues.SatisfyingEventsDelta.Updated);
                Assert.Empty(newValues.SatisfyingEventsDelta.Added);

                Assert.Empty(newValues.EventsToClearDelta.Updated);
                Assert.Empty(newValues.EventsToClearDelta.Added);

                Assert.Empty(newValues.EventsToUpdateDelta.Updated);
                Assert.Empty(newValues.EventsToUpdateDelta.Added);
            }

            [Fact]
            public void HandlesMultiUseParentAdd()
            {
                var f = new RelatedEventFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var multiRule = new RelatedEventRuleBuilder().Build();
                DataFiller.Fill(multiRule);
                multiRule.IsSatisfyingEvent = true;
                multiRule.IsClearEvent = true;
                multiRule.UpdateEvent = 1;

                parent.RelatedEvents.Add(multiRule);

                f.Subject.Reset(newValues, parent, criteria);

                var satisfyingEvent = newValues.SatisfyingEventsDelta.Added.First();
                var eventToClear = newValues.EventsToClearDelta.Added.First();
                var eventToUpdate = newValues.EventsToUpdateDelta.Added.First();

                Assert.True(satisfyingEvent.IsSatisfyingEvent);
                Assert.False(satisfyingEvent.IsUpdateEvent);
                Assert.False(satisfyingEvent.IsClearEvent);

                Assert.False(eventToClear.IsSatisfyingEvent);
                Assert.True(eventToClear.IsClearEvent);
                Assert.False(eventToClear.IsUpdateEvent);

                Assert.False(eventToUpdate.IsSatisfyingEvent);
                Assert.False(eventToUpdate.IsClearEvent);
                Assert.True(eventToUpdate.IsUpdateEvent);
            }

            [Fact]
            public void HandlesMultiUseParentUpdate()
            {
                var f = new RelatedEventFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var multiRule = new RelatedEventRuleBuilder().Build();
                DataFiller.Fill(multiRule);
                multiRule.IsSatisfyingEvent = true;
                multiRule.IsClearEvent = true;
                multiRule.UpdateEvent = 1;

                parent.RelatedEvents.Add(multiRule);

                var se = new RelatedEventRule();
                se.CopySatisfyingEvent(multiRule);
                var etc = new RelatedEventRule();
                etc.CopyEventToClear(multiRule);
                var etu = new RelatedEventRule();
                etu.CopyEventToUpdate(multiRule);
                criteria.RelatedEvents.AddRange(new[] {se, etc, etu});

                f.Subject.Reset(newValues, parent, criteria);

                var satisfyingEvent = newValues.SatisfyingEventsDelta.Updated.First();
                var eventToClear = newValues.EventsToClearDelta.Updated.First();
                var eventToUpdate = newValues.EventsToUpdateDelta.Updated.First();

                Assert.True(satisfyingEvent.IsSatisfyingEvent);
                Assert.False(satisfyingEvent.IsUpdateEvent);
                Assert.False(satisfyingEvent.IsClearEvent);

                Assert.False(eventToClear.IsSatisfyingEvent);
                Assert.True(eventToClear.IsClearEvent);
                Assert.False(eventToClear.IsUpdateEvent);

                Assert.False(eventToUpdate.IsSatisfyingEvent);
                Assert.False(eventToUpdate.IsClearEvent);
                Assert.True(eventToUpdate.IsUpdateEvent);
            }

            [Fact]
            public void UpdatesIfExisting()
            {
                var f = new RelatedEventFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var satisfyingEventRule = new RelatedEventRuleBuilder().AsSatisfyingEvent().Build();
                satisfyingEventRule.RelativeCycleId = 1;
                var eventToClearRule = new RelatedEventRuleBuilder().AsEventToClear().Build();
                var eventToUpdateRule = new RelatedEventRuleBuilder().AsEventToUpdate().Build();
                parent.RelatedEvents.AddRange(new[] {satisfyingEventRule, eventToClearRule, eventToUpdateRule});
                criteria.RelatedEvents.AddRange(new[] {satisfyingEventRule, eventToClearRule, eventToUpdateRule});

                f.Subject.Reset(newValues, parent, criteria);

                var satisfyingEvent = newValues.SatisfyingEventsDelta.Updated.First();
                var eventToClear = newValues.EventsToClearDelta.Updated.First();
                var eventToUpdate = newValues.EventsToUpdateDelta.Updated.First();

                Assert.Equal(satisfyingEventRule.HashKey(), satisfyingEvent.OriginalHashKey);
                Assert.Equal(eventToClearRule.HashKey(), eventToClear.OriginalHashKey);
                Assert.Equal(eventToUpdateRule.HashKey(), eventToUpdate.OriginalHashKey);

                Assert.Equal(satisfyingEventRule.RelatedEventId, satisfyingEvent.OriginalRelatedEventId);
                Assert.Equal(eventToClearRule.RelatedEventId, eventToClear.OriginalRelatedEventId);
                Assert.Equal(eventToUpdateRule.RelatedEventId, eventToUpdate.OriginalRelatedEventId);

                Assert.Empty(newValues.SatisfyingEventsDelta.Added);
                Assert.Empty(newValues.SatisfyingEventsDelta.Deleted);

                Assert.Empty(newValues.EventsToClearDelta.Added);
                Assert.Empty(newValues.EventsToClearDelta.Deleted);

                Assert.Empty(newValues.EventsToUpdateDelta.Added);
                Assert.Empty(newValues.EventsToUpdateDelta.Deleted);
            }
        }
    }

    public class RelatedEventFixture : IFixture<RelatedEvent>
    {
        public RelatedEventFixture()
        {
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
            RelatedEventService = Substitute.For<IRelatedEventService>();
            Subject = new RelatedEvent(WorkflowEventInheritanceService, RelatedEventService);
        }

        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }
        public IRelatedEventService RelatedEventService { get; }
        public RelatedEvent Subject { get; }

        public ValidEvent SetupValidEvent()
        {
            var baseEvent = new Event(Fixture.Integer());
            var criteria = new CriteriaBuilder().Build();
            var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();

            return eventRule;
        }
    }
}