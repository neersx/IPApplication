using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEventInheritanceServiceFacts
    {
        public class InheritNewEventRulesMethod : FactBase
        {
            public InheritNewEventRulesMethod()
            {
                _fixture = new WorkflowEventInheritanceServiceFixture(Db);
                _criteria = new CriteriaBuilder().Build();
            }

            readonly WorkflowEventInheritanceServiceFixture _fixture;
            readonly Criteria _criteria;

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void HandlesAddingEventsToCriteriaWithNoEvents(bool replaceEvent)
            {
                var parentEvent1 = new ValidEventBuilder().Build().In(Db);

                _fixture.Subject.InheritNewEventRules(_criteria, new[] {parentEvent1}, replaceEvent);

                Assert.NotNull(_fixture.DbContext.Set<ValidEvent>().SingleOrDefault(_ => _.CriteriaId == _criteria.Id && _.EventId == parentEvent1.EventId));
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void AddEventsFromParentInCorrectOrder(bool replaceEvents)
            {
                var commonEvent = new EventBuilder().Build();

                var childCommonEvent = new ValidEventBuilder {Description = "Child Common Event", DisplaySequence = 1}.For(_criteria, commonEvent).Build().In(Db);
                var childEvent1 = new ValidEventBuilder {DisplaySequence = 4}.For(_criteria, null).Build().In(Db);
                _criteria.ValidEvents = new[] {childCommonEvent, childEvent1};

                var parentCommonEvent = new ValidEventBuilder {Description = "Parent Common Event", DisplaySequence = 4}.For(null, commonEvent).Build().In(Db);
                var parentEvent3 = new ValidEventBuilder {DisplaySequence = 2}.Build().In(Db);
                var parentEvent2 = new ValidEventBuilder {DisplaySequence = 1}.Build().In(Db);
                var parentEvent1 = new ValidEventBuilder {DisplaySequence = 0}.Build().In(Db);

                _fixture.Subject.InheritNewEventRules(_criteria, new[] {parentEvent3, parentEvent1, parentEvent2, parentCommonEvent}, replaceEvents);
                var dbEventsResult = _fixture.DbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == _criteria.Id).OrderBy(_ => _.DisplaySequence).ToArray();

                Assert.Equal(childCommonEvent.EventId, dbEventsResult[0].EventId);
                Assert.Equal(childEvent1.EventId, dbEventsResult[1].EventId);
                Assert.Equal(parentEvent1.EventId, dbEventsResult[2].EventId);
                Assert.Equal(parentEvent2.EventId, dbEventsResult[3].EventId);
                Assert.Equal(parentEvent3.EventId, dbEventsResult[4].EventId);

                Assert.Equal(1, dbEventsResult[0].DisplaySequence.GetValueOrDefault());
                Assert.Equal(4, dbEventsResult[1].DisplaySequence.GetValueOrDefault());
                Assert.Equal(5, dbEventsResult[2].DisplaySequence.GetValueOrDefault());
                Assert.Equal(6, dbEventsResult[3].DisplaySequence.GetValueOrDefault());
                Assert.Equal(7, dbEventsResult[4].DisplaySequence.GetValueOrDefault());
            }

            [Fact]
            public void AddNonExistingAndReplaceCommonEvents()
            {
                var commonEvent = new EventBuilder().Build();
                var childCommonEvent = new ValidEventBuilder {Description = "Child Common Event"}.For(_criteria, commonEvent).Build().In(Db);
                var childEvent1 = new ValidEventBuilder().For(_criteria, null).Build().In(Db);
                _criteria.ValidEvents = new[] {childCommonEvent, childEvent1};

                var parentCommonEvent = new ValidEventBuilder {Description = "Parent Common Event"}.For(null, commonEvent).Build().In(Db);
                var parentEvent1 = new ValidEventBuilder().Build().In(Db);

                _fixture.Subject.InheritNewEventRules(_criteria, new[] {parentEvent1, parentCommonEvent}, true);
                var dbEventsResult = _fixture.DbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == _criteria.Id);

                Assert.Equal(3, dbEventsResult.Count());
                Assert.Equal("Parent Common Event", dbEventsResult.Single(_ => _.EventId == commonEvent.Id).Description);
                Assert.True(dbEventsResult.Any(_ => _.EventId == childEvent1.EventId));
                Assert.True(dbEventsResult.Any(_ => _.EventId == parentEvent1.EventId));
            }

            [Fact]
            public void AddOnlyNonExistingEvents()
            {
                var commonEvent = new EventBuilder().Build();

                var childCommonEvent = new ValidEventBuilder {Description = "Child Common Event"}.For(_criteria, commonEvent).Build().In(Db);
                var childEvent1 = new ValidEventBuilder().For(_criteria, null).Build().In(Db);
                _criteria.ValidEvents = new[] {childCommonEvent, childEvent1};

                var parentCommonEvent = new ValidEventBuilder {Description = "Parent Common Event"}.For(null, commonEvent).Build().In(Db);
                var parentEvent1 = new ValidEventBuilder().Build().In(Db);

                _fixture.Subject.InheritNewEventRules(_criteria, new[] {parentEvent1, parentCommonEvent}, false);
                var dbEventsResult = _fixture.DbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == _criteria.Id);

                Assert.Equal(3, dbEventsResult.Count());
                Assert.Equal("Child Common Event", dbEventsResult.Single(_ => _.EventId == commonEvent.Id).Description);
                Assert.True(dbEventsResult.Any(_ => _.EventId == childEvent1.EventId));
                Assert.True(dbEventsResult.Any(_ => _.EventId == parentEvent1.EventId));
            }

            [Fact]
            public void ReturnsAddedNonExistingAndReplacedCommonEventsWithCorrectSequence()
            {
                var commonEvent = new EventBuilder().Build();

                var childCommonEvent = new ValidEventBuilder {Description = "Child Common Event", DisplaySequence = 1}.For(_criteria, commonEvent).Build();
                var childEvent1 = new ValidEventBuilder {DisplaySequence = 4}.For(_criteria, null).Build();
                _criteria.ValidEvents = new[] {childCommonEvent, childEvent1};

                var parentCommonEvent = new ValidEventBuilder {Description = "Parent Common Event", DisplaySequence = 4}.For(null, commonEvent).Build();
                var parentEvent3 = new ValidEventBuilder {DisplaySequence = 2}.Build();
                var parentEvent2 = new ValidEventBuilder {DisplaySequence = 1}.Build();
                var parentEvent1 = new ValidEventBuilder {DisplaySequence = 0}.Build();

                var inheritedEventsResult = _fixture.Subject.InheritNewEventRules(_criteria, new[] {parentEvent3, parentEvent1, parentEvent2, parentCommonEvent}, true).OrderBy(_ => _.DisplaySequence).ToArray();

                Assert.Equal(4, inheritedEventsResult.Length);

                Assert.Equal(parentCommonEvent.EventId, inheritedEventsResult[0].EventId);
                Assert.Equal(parentEvent1.EventId, inheritedEventsResult[1].EventId);
                Assert.Equal(parentEvent2.EventId, inheritedEventsResult[2].EventId);
                Assert.Equal(parentEvent3.EventId, inheritedEventsResult[3].EventId);

                Assert.Equal(1, inheritedEventsResult[0].DisplaySequence.GetValueOrDefault());
                Assert.Equal(5, inheritedEventsResult[1].DisplaySequence.GetValueOrDefault());
                Assert.Equal(6, inheritedEventsResult[2].DisplaySequence.GetValueOrDefault());
                Assert.Equal(7, inheritedEventsResult[3].DisplaySequence.GetValueOrDefault());
            }

            [Fact]
            public void ReturnsAddedNonExistingEventsWithCorrectSequence()
            {
                var commonEvent = new EventBuilder().Build();

                var childCommonEvent = new ValidEventBuilder {Description = "Child Common Event", DisplaySequence = 1}.For(_criteria, commonEvent).Build();
                var childEvent1 = new ValidEventBuilder {DisplaySequence = 4}.For(_criteria, null).Build();
                _criteria.ValidEvents = new[] {childCommonEvent, childEvent1};

                var parentCommonEvent = new ValidEventBuilder {Description = "Parent Common Event", DisplaySequence = 4}.For(null, commonEvent).Build();
                var parentEvent3 = new ValidEventBuilder {DisplaySequence = 2}.Build();
                var parentEvent2 = new ValidEventBuilder {DisplaySequence = 1}.Build();
                var parentEvent1 = new ValidEventBuilder {DisplaySequence = 0}.Build();

                var inheritedEventsResult = _fixture.Subject.InheritNewEventRules(_criteria, new[] {parentEvent3, parentEvent1, parentEvent2, parentCommonEvent}, false).ToArray();

                Assert.Equal(3, inheritedEventsResult.Length);

                Assert.Equal(parentEvent1.EventId, inheritedEventsResult[0].EventId);
                Assert.Equal(parentEvent2.EventId, inheritedEventsResult[1].EventId);
                Assert.Equal(parentEvent3.EventId, inheritedEventsResult[2].EventId);

                Assert.Equal(5, inheritedEventsResult[0].DisplaySequence.GetValueOrDefault());
                Assert.Equal(6, inheritedEventsResult[1].DisplaySequence.GetValueOrDefault());
                Assert.Equal(7, inheritedEventsResult[2].DisplaySequence.GetValueOrDefault());
            }
        }

        public class DeletesCommonEventsMethod : FactBase
        {
            [Fact]
            public void DeletesCommonEvents()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);
                var criteria = new CriteriaBuilder().Build();
                var @event = new EventBuilder().Build();
                criteria.ValidEvents = new[]
                {
                    new ValidEventBuilder().For(criteria, @event).BuildWithDatesLogic(Db, 2),
                    new ValidEventBuilder().For(criteria, null).Build()
                }.In(Db);
                new ValidEventBuilder().For(null, @event).Build().In(Db);

                f.Subject.DeleteCommonEventsFromChild(criteria, new[] {@event.Id});

                Assert.False(f.DbContext.Set<DatesLogic>().Any(_ => _.CriteriaId == criteria.Id && _.EventId == @event.Id));
                Assert.False(f.DbContext.Set<ValidEvent>().Any(_ => _.CriteriaId == criteria.Id && _.EventId == @event.Id));
            }
        }

        public class InheritValidEventRuleMethod : FactBase
        {
            [Fact]
            public void ReturnsNewValidEvent()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);
                var criteria = new CriteriaBuilder().Build();
                var parentEvent = new ValidEventBuilder().Build();
                DataFiller.Fill(parentEvent);
                parentEvent.IsInherited = false;

                var dueDateCalcBuilder = new DueDateCalcBuilder().For(parentEvent);
                parentEvent.DueDateCalcs = new[] {dueDateCalcBuilder.Build(), dueDateCalcBuilder.Build()};

                var datesLogicBuilder = new DatesLogicBuilder().For(parentEvent);
                parentEvent.DatesLogic = new[] {datesLogicBuilder.Build(), datesLogicBuilder.Build()};

                var relatedEventsBuilder = new RelatedEventRuleBuilder().For(parentEvent);
                parentEvent.RelatedEvents = new[] {relatedEventsBuilder.Build(), relatedEventsBuilder.Build()};

                var reminderRuleBuilder = new ReminderRuleBuilder().For(parentEvent);
                parentEvent.Reminders = new[] {reminderRuleBuilder.Build(), reminderRuleBuilder.Build()};

                var nameTypeMapBuilder = new NameTypeMapBuilder().For(parentEvent);
                parentEvent.NameTypeMaps = new[] {nameTypeMapBuilder.Build(), nameTypeMapBuilder.Build()};

                var requiredEventRuleBuilder = new RequiredEventRuleBuilder().For(parentEvent);
                parentEvent.RequiredEvents = new[] {requiredEventRuleBuilder.Build(), requiredEventRuleBuilder.Build()};

                var newDisplaySequence = Fixture.Short();
                var result = f.Subject.InheritValidEventRule(criteria, parentEvent, newDisplaySequence);

                Assert.Equal(newDisplaySequence, result.DisplaySequence);
                Assert.Equal(criteria.Id, result.CriteriaId);
                Assert.Equal(parentEvent.EventId, result.EventId);
                Assert.Equal(parentEvent.Description, result.Description);
                Assert.True(result.IsInherited);

                Assert.Equal(2, result.DueDateCalcs.Count);
                Assert.Equal(2, result.DueDateCalcs.Select(_ => _.Sequence).Distinct().Count());
                Assert.True(result.DueDateCalcs.All(_ => _.IsInherited));

                Assert.Equal(2, result.DatesLogic.Count);
                Assert.Equal(2, result.DatesLogic.Select(_ => _.Sequence).Distinct().Count());
                Assert.True(result.DatesLogic.All(_ => _.IsInherited));

                Assert.Equal(2, result.RelatedEvents.Count);
                Assert.Equal(2, result.RelatedEvents.Select(_ => _.Sequence).Distinct().Count());
                Assert.True(result.RelatedEvents.All(_ => _.IsInherited));

                Assert.Equal(2, result.Reminders.Count);
                Assert.Equal(2, result.Reminders.Select(_ => _.Sequence).Distinct().Count());
                Assert.True(result.Reminders.All(_ => _.IsInherited));

                Assert.Equal(2, result.NameTypeMaps.Count);
                Assert.Equal(2, result.NameTypeMaps.Select(_ => _.Sequence).Distinct().Count());
                Assert.True(result.NameTypeMaps.All(_ => _.Inherited));

                Assert.Equal(2, result.RequiredEvents.Count);
                Assert.True(result.RequiredEvents.All(_ => _.Inherited));
            }
        }

        public class SetInheritedFieldsToUpdateMethod : FactBase
        {
            [Fact]
            public void SetsFlagsFalseForChangeAction()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    OpenActionId = "A",
                    CloseActionId = "B",
                    RelativeCycle = 3
                }.Build();

                var childEvent = new ValidEventBuilder
                {
                    OpenActionId = "C",
                    CloseActionId = "B",
                    RelativeCycle = 2,
                    Inherited = true
                }.Build();

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.False(shouldInherit.OpenActionId);
                Assert.False(shouldInherit.CloseActionId);
                Assert.False(shouldInherit.RelativeCycle);
            }

            [Fact]
            public void SetsFlagsFalseForDueDateCalcSettings()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    SaveDueDate = 0,
                    DateToUse = "E",
                    RecalcDueDate = false,
                    ExtendPeriod = 3,
                    ExtendPeriodType = "M",
                    SuppressDueDateCalculation = true
                }.Build();

                var childEvent = new ValidEventBuilder().Build();

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.False(shouldInherit.IsSaveDueDate);
                Assert.False(shouldInherit.DateToUse);
                Assert.False(shouldInherit.RecalcEventDate);
                Assert.False(shouldInherit.ExtendPeriod);
                Assert.False(shouldInherit.ExtendPeriodType);
                Assert.False(shouldInherit.SuppressDueDateCalculation);
            }

            [Fact]
            public void SetsFlagsFalseForNonMatchingValues()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    Description = "same description",
                    ImportanceLevel = "same importance",
                    MaxCycles = 1,
                    Notes = "same notes"
                }.Build();

                var childEvent = new ValidEventBuilder
                {
                    Description = "different description",
                    ImportanceLevel = "different importance",
                    MaxCycles = 2,
                    Notes = "different notes"
                }.Build();

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    Description = true,
                    ImportanceLevel = true,
                    Notes = true,
                    NumberOfCyclesAllowed = true
                };

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.False(shouldInherit.Description);
                Assert.False(shouldInherit.ImportanceLevel);
                Assert.False(shouldInherit.Notes);
                Assert.False(shouldInherit.NumberOfCyclesAllowed);
            }

            [Fact]
            public void SetsFlagsFalseForReportToCpa()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    IsThirdPartyOn = true,
                    IsThirdPartyOff = false
                }.Build();

                var childEvent = new ValidEventBuilder
                {
                    IsThirdPartyOn = false,
                    IsThirdPartyOff = false
                }.Build();

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.False(shouldInherit.SetThirdPartyOn);
                Assert.False(shouldInherit.IsThirdPartyOff);
            }

            [Fact]
            public void SetsFlagsFalseForStandingInstructionSettings()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    FlagNumber = 1,
                    InstructionType = "A"
                }.Build();

                var childEvent = new ValidEventBuilder
                {
                    FlagNumber = 1,
                    InstructionType = "B",
                    Inherited = true
                }.Build();

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.False(shouldInherit.FlagNumber);
                Assert.False(shouldInherit.InstructionType);
            }

            [Fact]
            public void SetsFlagsTrueForChangeAction()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    OpenActionId = "A",
                    CloseActionId = "B",
                    RelativeCycle = 3
                }.Build();

                var childEvent = new ValidEventBuilder
                {
                    OpenActionId = "A",
                    CloseActionId = "B",
                    RelativeCycle = 3,
                    Inherited = true
                }.Build();

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.True(shouldInherit.OpenActionId);
                Assert.True(shouldInherit.CloseActionId);
                Assert.True(shouldInherit.RelativeCycle);
            }

            [Fact]
            public void SetsFlagsTrueForDueDateCalcSettings()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    SaveDueDate = 0,
                    DateToUse = "E",
                    RecalcDueDate = false,
                    ExtendPeriod = 3,
                    ExtendPeriodType = "M",
                    SuppressDueDateCalculation = true
                }.Build();

                var childEvent = new ValidEventBuilder().Build();
                childEvent.InheritRulesFrom(parentEvent);

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.True(shouldInherit.IsSaveDueDate);
                Assert.True(shouldInherit.DateToUse);
                Assert.True(shouldInherit.RecalcEventDate);
                Assert.True(shouldInherit.ExtendPeriod);
                Assert.True(shouldInherit.ExtendPeriodType);
                Assert.True(shouldInherit.SuppressDueDateCalculation);
            }

            [Fact]
            public void SetsFlagsTrueForMatchingValues()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    Description = "same description",
                    ImportanceLevel = "same importance",
                    MaxCycles = 1,
                    Notes = "same notes"
                }.Build();

                var childEvent = new ValidEventBuilder
                {
                    Description = "same description",
                    ImportanceLevel = "same importance",
                    MaxCycles = 1,
                    Notes = "same notes"
                }.Build();

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    Description = true,
                    ImportanceLevel = true,
                    Notes = true,
                    NumberOfCyclesAllowed = true
                };

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.True(shouldInherit.Description);
                Assert.True(shouldInherit.ImportanceLevel);
                Assert.True(shouldInherit.Notes);
                Assert.True(shouldInherit.NumberOfCyclesAllowed);
            }

            [Fact]
            public void SetsFlagsTrueForReportToCpa()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    IsThirdPartyOn = true,
                    IsThirdPartyOff = false
                }.Build();

                var childEvent = new ValidEventBuilder
                {
                    IsThirdPartyOn = true,
                    IsThirdPartyOff = false
                }.Build();

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.True(shouldInherit.SetThirdPartyOn);
                Assert.True(shouldInherit.IsThirdPartyOff);
            }

            [Fact]
            public void SetsFlagsTrueForStandingInstructionSettings()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    FlagNumber = 1,
                    InstructionType = "A"
                }.Build();

                var childEvent = new ValidEventBuilder
                {
                    FlagNumber = 1,
                    InstructionType = "A",
                    Inherited = true
                }.Build();

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.True(shouldInherit.FlagNumber);
                Assert.True(shouldInherit.InstructionType);
            }
        }

        public class SetInheritedDatesLogicComparisonMethod : FactBase
        {
            [Fact]
            public void SetsFlagsFalseForLoadEvent()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    SyncedFromCase = 1,
                    UseReceivingCycle = true,
                    SyncedEventId = 123,
                    SyncedCaseRelationshipId = "A",
                    SyncedNumberTypeId = "B",
                    SyncedEventDateAdjustmentId = "C"
                }.Build();

                var childEvent = new ValidEventBuilder().Build();

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.False(shouldInherit.SyncedFromCase);
                Assert.False(shouldInherit.UseReceivingCycle);
                Assert.False(shouldInherit.SyncedEventId);
                Assert.False(shouldInherit.SyncedCaseRelationshipId);
                Assert.False(shouldInherit.SyncedNumberTypeId);
                Assert.False(shouldInherit.SyncedEventDateAdjustmentId);
            }

            [Fact]
            public void SetsFlagsTrueForLoadEvent()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentEvent = new ValidEventBuilder
                {
                    SyncedFromCase = 1,
                    UseReceivingCycle = true,
                    SyncedEventId = 123,
                    SyncedCaseRelationshipId = "A",
                    SyncedNumberTypeId = "B",
                    SyncedEventDateAdjustmentId = "C"
                }.Build();

                var childEvent = new ValidEventBuilder().Build();
                childEvent.InheritRulesFrom(parentEvent);

                var shouldInherit = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedFieldsToUpdate(childEvent, parentEvent, shouldInherit);

                Assert.True(shouldInherit.SyncedFromCase);
                Assert.True(shouldInherit.UseReceivingCycle);
                Assert.True(shouldInherit.SyncedEventId);
                Assert.True(shouldInherit.SyncedCaseRelationshipId);
                Assert.True(shouldInherit.SyncedNumberTypeId);
                Assert.True(shouldInherit.SyncedEventDateAdjustmentId);
            }

            [Fact]
            public void SetsInheritedFlagFalseIfAnyDateComparisonNotInherited()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);
                var eventControl = new ValidEvent();
                eventControl.DueDateCalcs = new[]
                {
                    new DueDateCalc
                    {
                        Comparison = "=",
                        IsInherited = true
                    },

                    new DueDateCalc
                    {
                        Comparison = "<",
                        IsInherited = false
                    }
                };

                var eventControlFieldsToUpdate = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedDatesLogicComparison(eventControl, eventControlFieldsToUpdate);

                Assert.False(eventControlFieldsToUpdate.DatesLogicComparison);
            }

            [Fact]
            public void SetsInheritedFlagTrueIfAllDateComparisonInherited()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);
                var eventControl = new ValidEvent();
                eventControl.DueDateCalcs = new[]
                {
                    new DueDateCalc
                    {
                        Comparison = "=",
                        IsInherited = true
                    },

                    new DueDateCalc
                    {
                        Comparison = "<",
                        IsInherited = true
                    }
                };

                var eventControlFieldsToUpdate = new EventControlFieldsToUpdate();

                f.Subject.SetInheritedDatesLogicComparison(eventControl, eventControlFieldsToUpdate);

                Assert.True(eventControlFieldsToUpdate.DatesLogicComparison);
            }
        }

        public class GetInheritDeltaMethod : FactBase
        {
            // todo: complete these tests.

            [Fact]
            public void ReturnsAddedItemsNotInChild()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentDelta = new Delta<int>();
                parentDelta.Added.AddRange(new[] {1, 2, 3});

                Func<bool, IEnumerable<int>> getHash = b => b ? new int[0] : new[] {2};

                var result = f.Subject.GetInheritDelta(() => parentDelta, getHash);
                Assert.True(result.Added.Contains(1));
                Assert.True(result.Added.Contains(3));
                Assert.False(result.Added.Contains(2));
            }

            [Fact]
            public void ReturnsDeletedItemsCommonInChild()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentDelta = new Delta<int>();
                parentDelta.Deleted.AddRange(new[] {1, 2, 3, 4});

                Func<bool, IEnumerable<int>> getHash = b => b ? new[] {2} : new int[0];

                var result = f.Subject.GetInheritDelta(() => parentDelta, getHash);
                Assert.True(result.Deleted.Contains(2));
                Assert.False(result.Deleted.Contains(4));
                Assert.False(result.Deleted.Contains(1));
                Assert.False(result.Deleted.Contains(3));
            }

            [Fact]
            public void ReturnsUpdatedItemsCommonInChild()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var parentDelta = new Delta<int>();
                parentDelta.Updated.AddRange(new[] {1, 2, 3, 4});

                Func<bool, IEnumerable<int>> getHash = b => b ? new[] {2, 4} : new int[0];

                var result = f.Subject.GetInheritDelta(() => parentDelta, getHash);
                Assert.True(result.Updated.Contains(2));
                Assert.True(result.Updated.Contains(4));
                Assert.False(result.Updated.Contains(1));
                Assert.False(result.Updated.Contains(3));
            }
        }

        public class GetDeltaMethod : FactBase
        {
            [Fact]
            public void ReturnsAddedValuesMatchingHashkey()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var newDelta = new Delta<string>();
                var items = new[] {"A", "B", "C", "D"};
                newDelta.Added.AddRange(items);

                var shouldUpdate = new Delta<int>();
                shouldUpdate.Added = new[] {0, 2};
                Func<string, int> getHashDelegate = s => Array.IndexOf(items, s);
                Func<string, int> getOriginalHashKeyDelegate = s => -1;

                var result = f.Subject.GetDelta(newDelta, shouldUpdate, getHashDelegate, getOriginalHashKeyDelegate);

                Assert.True(result.Added.Contains("A"));
                Assert.True(result.Added.Contains("C"));
                Assert.False(result.Added.Contains("B"));
                Assert.False(result.Added.Contains("D"));
            }

            [Fact]
            public void ReturnsDeletedValuesMatchingOriginalHashkey()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var newDelta = new Delta<string>();
                var items = new[] {"A", "B", "C", "D"};
                newDelta.Deleted.AddRange(items);

                var shouldUpdate = new Delta<int>();
                shouldUpdate.Deleted = new[] {2, 3, 99};

                Func<string, int> getHashDelegate = s => -1;
                Func<string, int> getOriginalHashKeyDelegate = s => Array.IndexOf(items, s);

                var result = f.Subject.GetDelta(newDelta, shouldUpdate, getHashDelegate, getOriginalHashKeyDelegate);

                Assert.True(result.Deleted.Contains("C"));
                Assert.True(result.Deleted.Contains("D"));
                Assert.False(result.Deleted.Contains("A"));
                Assert.False(result.Deleted.Contains("B"));
            }

            [Fact]
            public void ReturnsUpdatedValuesMatchingOriginalHashkey()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);

                var newDelta = new Delta<string>();
                var items = new[] {"A", "B", "C", "D"};
                newDelta.Updated.AddRange(items);

                var shouldUpdate = new Delta<int>();
                shouldUpdate.Updated = new[] {1, 3};

                Func<string, int> getHashDelegate = s => -1;
                Func<string, int> getOriginalHashKeyDelegate = s => Array.IndexOf(items, s);

                var result = f.Subject.GetDelta(newDelta, shouldUpdate, getHashDelegate, getOriginalHashKeyDelegate);

                Assert.True(result.Updated.Contains("B"));
                Assert.True(result.Updated.Contains("D"));
                Assert.False(result.Updated.Contains("A"));
                Assert.False(result.Updated.Contains("C"));
            }
        }

        public class GenerateEventControlFieldsToUpdateMethod : FactBase
        {
            [Fact]
            public void GeneratesDeltaForAllSections()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);
                var saveModel = new WorkflowEventControlSaveModel();
                saveModel.DueDateCalcDelta.Added.Add(new DueDateCalcSaveModel());
                saveModel.DateComparisonDelta.Updated.Add(new DateComparisonSaveModel());
                saveModel.SatisfyingEventsDelta.Deleted.Add(new RelatedEventRuleSaveModel());
                saveModel.EventsToClearDelta.Added.Add(new RelatedEventRuleSaveModel());
                saveModel.EventsToUpdateDelta.Updated.Add(new RelatedEventRuleSaveModel());
                saveModel.ReminderRuleDelta.Deleted.Add(new ReminderRuleSaveModel());
                saveModel.DocumentDelta.Added.Add(new ReminderRuleSaveModel());
                saveModel.DesignatedJurisdictionsDelta.Deleted.Add(Fixture.String());
                saveModel.DatesLogicDelta.Deleted.Add(new DatesLogicSaveModel());

                var result = f.Subject.GenerateEventControlFieldsToUpdate(saveModel);
                Assert.NotEmpty(result.DueDateCalcsDelta.Added);
                Assert.Empty(result.DueDateCalcsDelta.Updated.Union(result.DueDateCalcsDelta.Deleted));
                Assert.NotEmpty(result.DateComparisonDelta.Updated);
                Assert.NotEmpty(result.SatisfyingEventsDelta.Deleted);
                Assert.NotEmpty(result.EventsToClearDelta.Added);
                Assert.NotEmpty(result.EventsToUpdateDelta.Updated);
                Assert.NotEmpty(result.ReminderRulesDelta.Deleted);
                Assert.NotEmpty(result.DocumentsDelta.Added);
                Assert.NotEmpty(result.DesignatedJurisdictionsDelta.Deleted);
                Assert.NotEmpty(result.DatesLogicDelta.Deleted);
            }

            [Fact]
            public void GeneratesDeltaWithHashKeys()
            {
                var f = new WorkflowEventInheritanceServiceFixture(Db);
                var saveModel = new WorkflowEventControlSaveModel();
                var eventControl = new ValidEventBuilder().Build();
                var addDueDateCalc = new DueDateCalcSaveModelBuilder().For(eventControl).Build();
                var updateDueDateCalc = new DueDateCalcSaveModelBuilder().For(eventControl).Build();
                var deletedDueDateCalc = new DueDateCalcSaveModelBuilder().For(eventControl).Build();
                DataFiller.Fill(addDueDateCalc);
                DataFiller.Fill(updateDueDateCalc);
                DataFiller.Fill(deletedDueDateCalc);
                saveModel.DueDateCalcDelta = new Delta<DueDateCalcSaveModel>
                {
                    Added = new[] {addDueDateCalc},
                    Updated = new[] {updateDueDateCalc},
                    Deleted = new[] {deletedDueDateCalc}
                };

                saveModel.DesignatedJurisdictionsDelta.Added.Add(Fixture.String());
                saveModel.DesignatedJurisdictionsDelta.Deleted.Add(Fixture.String());

                var result = f.Subject.GenerateEventControlFieldsToUpdate(saveModel);
                Assert.Equal(addDueDateCalc.HashKey(), result.DueDateCalcsDelta.Added.First());
                Assert.Equal(updateDueDateCalc.OriginalHashKey, result.DueDateCalcsDelta.Updated.First());
                Assert.Equal(deletedDueDateCalc.OriginalHashKey, result.DueDateCalcsDelta.Deleted.First());
                Assert.Equal(saveModel.DesignatedJurisdictionsDelta.Added.Single(), result.DesignatedJurisdictionsDelta.Added.Single());
                Assert.Equal(saveModel.DesignatedJurisdictionsDelta.Deleted.Single(), result.DesignatedJurisdictionsDelta.Deleted.Single());
            }
        }

        public class BreakEventInheritanceMethod : FactBase
        {
            readonly Criteria _criteria;
            readonly Event _event;
            readonly Event _event2;
            readonly WorkflowEventInheritanceServiceFixture _serviceFixture;

            public BreakEventInheritanceMethod()
            {
                _serviceFixture = new WorkflowEventInheritanceServiceFixture(Db);
                _criteria = new CriteriaBuilder {ParentCriteriaId = Fixture.Integer()}.Build().In(Db);
                _event = new EventBuilder().Build().In(Db);
                _event2 = new EventBuilder().Build().In(Db);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetsEventInheritedFlagFalseParentCriteriaAndParentEventToNull(bool eventSpecific)
            {
                _criteria.ValidEvents = new[]
                {
                    new ValidEventBuilder().For(_criteria, _event).WithParentInheritance().Build(),
                    new ValidEventBuilder().For(_criteria, _event2).WithParentInheritance().Build()
                }.In(Db);

                _serviceFixture.Subject.BreakEventsInheritance(_criteria.Id, eventSpecific ? (int?) _event.Id : null);

                var events = _serviceFixture.DbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == _criteria.Id);
                Assert.Equal(2, events.Count());
                if (eventSpecific)
                {
                    Assert.NotNull(events.SingleOrDefault(_ => _.EventId == _event.Id && _.Inherited == 0));
                    Assert.NotNull(events.SingleOrDefault(_ => _.EventId != _event.Id && _.Inherited == 1));
                }
                else
                {
                    Assert.True(events.All(_ => _.Inherited == 0));
                    Assert.True(events.All(_ => _.ParentCriteriaNo == null));
                    Assert.True(events.All(_ => _.ParentEventNo == null));
                }
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetInheritedFlagFalseForDueDateCalcs(bool eventSpecific)
            {
                _criteria.ValidEvents = new[]
                {
                    new ValidEventBuilder().For(_criteria, _event).WithParentInheritance().BuildWithDueDateCalcs(Db, 2),
                    new ValidEventBuilder().For(_criteria, _event2).WithParentInheritance().BuildWithDueDateCalcs(Db, 2)
                }.In(Db);

                _serviceFixture.Subject.BreakEventsInheritance(_criteria.Id, eventSpecific ? (int?) _event.Id : null);

                var dueDates = _serviceFixture.DbContext.Set<DueDateCalc>().Where(_ => _.CriteriaId == _criteria.Id);
                Assert.Equal(4, dueDates.Count());

                if (eventSpecific)
                {
                    Assert.Equal(2, dueDates.Count(_ => _.EventId == _event.Id && _.Inherited == 0));
                    Assert.Equal(2, dueDates.Count(_ => _.EventId != _event.Id && _.Inherited == 1));
                }
                else
                {
                    Assert.True(dueDates.All(_ => !_.IsInherited));
                }
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetInheritedFlagFalseForRelatedEventRules(bool eventSpecific)
            {
                _criteria.ValidEvents = new[]
                {
                    new ValidEventBuilder().For(_criteria, _event).WithParentInheritance().BuildWithRelatedEvents(Db, 2),
                    new ValidEventBuilder().For(_criteria, _event2).WithParentInheritance().BuildWithRelatedEvents(Db, 2)
                }.In(Db);

                _serviceFixture.Subject.BreakEventsInheritance(_criteria.Id, eventSpecific ? (int?) _event.Id : null);

                var relatedEvents = _serviceFixture.DbContext.Set<RelatedEventRule>().Where(_ => _.CriteriaId == _criteria.Id);
                Assert.Equal(4, relatedEvents.Count());

                if (eventSpecific)
                {
                    Assert.Equal(2, relatedEvents.Count(_ => _.EventId == _event.Id && _.Inherited == 0));
                    Assert.Equal(2, relatedEvents.Count(_ => _.EventId != _event.Id && _.Inherited == 1));
                }
                else
                {
                    Assert.True(relatedEvents.All(_ => !_.IsInherited));
                }
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetInheritedFlagFalseForReminderRules(bool eventSpecific)
            {
                _criteria.ValidEvents = new[]
                {
                    new ValidEventBuilder().For(_criteria, _event).WithParentInheritance().BuildWithReminders(Db, 2),
                    new ValidEventBuilder().For(_criteria, _event2).WithParentInheritance().BuildWithReminders(Db, 2)
                }.In(Db);

                _serviceFixture.Subject.BreakEventsInheritance(_criteria.Id, eventSpecific ? (int?) _event.Id : null);

                var reminderRules = _serviceFixture.DbContext.Set<ReminderRule>().Where(_ => _.CriteriaId == _criteria.Id);
                Assert.Equal(4, reminderRules.Count());

                if (eventSpecific)
                {
                    Assert.Equal(2, reminderRules.Count(_ => _.EventId == _event.Id && _.Inherited == 0));
                    Assert.Equal(2, reminderRules.Count(_ => _.EventId != _event.Id && _.Inherited == 1));
                }
                else
                {
                    Assert.True(reminderRules.All(_ => !_.IsInherited));
                }
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetInheritedFlagFalseForDateLogicRules(bool eventSpecific)
            {
                _criteria.ValidEvents = new[]
                {
                    new ValidEventBuilder().For(_criteria, _event).WithParentInheritance().BuildWithDatesLogic(Db, 2),
                    new ValidEventBuilder().For(_criteria, _event2).WithParentInheritance().BuildWithDatesLogic(Db, 2)
                }.In(Db);

                _serviceFixture.Subject.BreakEventsInheritance(_criteria.Id, eventSpecific ? (int?) _event.Id : null);

                var dateLogics = _serviceFixture.DbContext.Set<DatesLogic>().Where(_ => _.CriteriaId == _criteria.Id);
                Assert.Equal(4, dateLogics.Count());

                if (eventSpecific)
                {
                    Assert.Equal(2, dateLogics.Count(_ => _.EventId == _event.Id && _.Inherited == 0));
                    Assert.Equal(2, dateLogics.Count(_ => _.EventId != _event.Id && _.Inherited == 1));
                }
                else
                {
                    Assert.True(dateLogics.All(_ => !_.IsInherited));
                }
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetInheritedFlagFalseForNameTypeMaps(bool eventSpecific)
            {
                _criteria.ValidEvents = new[]
                {
                    new ValidEventBuilder().For(_criteria, _event).WithParentInheritance().BuildWithNameTypeMaps(Db, 2),
                    new ValidEventBuilder().For(_criteria, _event2).WithParentInheritance().BuildWithNameTypeMaps(Db, 2)
                }.In(Db);

                _serviceFixture.Subject.BreakEventsInheritance(_criteria.Id, eventSpecific ? (int?) _event.Id : null);

                var nameTypeMaps = _serviceFixture.DbContext.Set<NameTypeMap>().Where(_ => _.CriteriaId == _criteria.Id);
                Assert.Equal(4, nameTypeMaps.Count());

                if (eventSpecific)
                {
                    Assert.Equal(2, nameTypeMaps.Count(_ => _.EventId == _event.Id && !_.Inherited));
                    Assert.Equal(2, nameTypeMaps.Count(_ => _.EventId != _event.Id && _.Inherited));
                }
                else
                {
                    Assert.True(nameTypeMaps.All(_ => !_.Inherited));
                }
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetInheritedFlagFalseForRequiredEvents(bool eventSpecific)
            {
                _criteria.ValidEvents = new[]
                {
                    new ValidEventBuilder().For(_criteria, _event).WithParentInheritance().BuildWithRequiredEvents(Db, 2),
                    new ValidEventBuilder().For(_criteria, _event2).WithParentInheritance().BuildWithRequiredEvents(Db, 2)
                }.In(Db);

                _serviceFixture.Subject.BreakEventsInheritance(_criteria.Id, eventSpecific ? (int?) _event.Id : null);

                var requiredEventRules = _serviceFixture.DbContext.Set<RequiredEventRule>().Where(_ => _.CriteriaId == _criteria.Id);
                Assert.Equal(4, requiredEventRules.Count());

                if (eventSpecific)
                {
                    Assert.Equal(2, requiredEventRules.Count(_ => _.EventId == _event.Id && !_.Inherited));
                    Assert.Equal(2, requiredEventRules.Count(_ => _.EventId != _event.Id && _.Inherited));
                }
                else
                {
                    Assert.True(requiredEventRules.All(_ => !_.Inherited));
                }
            }
        }
    }

    public class WorkflowEventInheritanceServiceFixture : IFixture<WorkflowEventInheritanceService>
    {
        public WorkflowEventInheritanceServiceFixture(InMemoryDbContext db)
        {
            DbContext = db;
            Subject = Substitute.ForPartsOf<WorkflowEventInheritanceService>(DbContext);
        }

        public IDbContext DbContext { get; set; }
        public WorkflowEventInheritanceService Subject { get; set; }
    }
}