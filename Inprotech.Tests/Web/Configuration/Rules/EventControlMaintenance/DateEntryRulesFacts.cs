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
    public class DateEntryRulesFacts
    {
        public class ValidateDatesLogicMethod
        {
            [Theory]
            [InlineData(null, -1, 1, 0, "ABC")]
            [InlineData("", -1, 1, 0, "ABC")]
            [InlineData("<", null, 1, 0, "ABC")]
            [InlineData("<", -1, null, 1, "ABC")]
            [InlineData("<", -1, 1, null, "ABC")]
            [InlineData("<", -1, 1, 1, null)]
            [InlineData("<", -1, 1, 1, "")]
            public void ReturnsErrorIfMissingMandatoryFields(string op, int? compareEventId, int? relativeCycle, int? displayErrorFlag, string message)
            {
                var f = new DateEntryRulesFixture();
                var criteria = new CriteriaBuilder().Build();

                var addModel = new DatesLogicSaveModelBuilder().Build();
                addModel.Operator = op;
                addModel.CompareEventId = compareEventId;
                addModel.RelativeCycle = (short?) relativeCycle;
                addModel.DisplayErrorFlag = displayErrorFlag;
                addModel.FailureMessage = message;

                var delta = new Delta<DatesLogicSaveModel> {Added = new[] {addModel}};
                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id, CriteriaId = criteria.Id, DatesLogicDelta = delta};
                var result = f.Subject.Validate(saveModel);
                Assert.NotEmpty(result);
            }

            [Fact]
            public void DoesNotReturnErrorIfMandatoryFieldsFilled()
            {
                var f = new DateEntryRulesFixture();
                var criteria = new CriteriaBuilder().Build();

                var addModel = new DatesLogicSaveModelBuilder().Build();
                addModel.Operator = "<";
                addModel.CompareEventId = -1;
                addModel.RelativeCycle = 1;
                addModel.DisplayErrorFlag = 1;
                addModel.FailureMessage = "ABC";

                var delta = new Delta<DatesLogicSaveModel> {Added = new[] {addModel}};
                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id, CriteriaId = criteria.Id, DatesLogicDelta = delta};
                var result = f.Subject.Validate(saveModel);
                Assert.Empty(result);
            }
        }

        public class ApplyDatesLogicChangesMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void AddsOrInheritsNewDatesLogic(bool inherit)
            {
                var f = new DateEntryRulesFixture();

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build();
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build();
                var sequence = Fixture.Short();
                eventRule.DatesLogic.Add(new DatesLogicBuilder {Sequence = sequence}.For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = inherit ? Fixture.Integer() : criteria.Id};
                var newDatesLogic = new DatesLogicSaveModelBuilder().For(eventRule).Build();
                saveModel.DatesLogicDelta.Added.Add(newDatesLogic);

                f.WorkflowEventInheritanceService.GetDelta(Arg.Any<Delta<DatesLogicSaveModel>>(), Arg.Any<Delta<int>>(), Arg.Any<Func<DatesLogicSaveModel, int>>(), Arg.Any<Func<DatesLogicSaveModel, int>>())
                 .ReturnsForAnyArgs(saveModel.DatesLogicDelta);

                f.Subject.ApplyChanges(eventRule, saveModel, new EventControlFieldsToUpdate());

                Assert.Equal(2, eventRule.DatesLogic.Count);
                var addedRule = eventRule.DatesLogic.SingleOrDefault(_ => _.CompareEventId == newDatesLogic.CompareEventId);
                Assert.NotNull(addedRule);
                Assert.Equal(sequence + 1, addedRule.Sequence);
                Assert.Equal(inherit, addedRule.IsInherited);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public void UpdatesOrInheritsDatesLogic(bool inherit)
            {
                var f = new DateEntryRulesFixture();

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build();
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build();
                var sequence = Fixture.Short();
                var existingDatesLogic = new DatesLogicBuilder {Sequence = sequence, Inherited = 1}.For(eventRule).Build();
                eventRule.DatesLogic.Add(existingDatesLogic);

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = inherit ? Fixture.Integer() : criteria.Id};
                var editedDatesLogic = new DatesLogicSaveModelBuilder().For(eventRule).Build();
                editedDatesLogic.OriginalHashKey = existingDatesLogic.HashKey();
                saveModel.DatesLogicDelta.Updated.Add(editedDatesLogic);

                Assert.NotEqual(eventRule.DatesLogic.Single().HashKey(), editedDatesLogic.HashKey());

                f.WorkflowEventInheritanceService.GetDelta(Arg.Any<Delta<DatesLogicSaveModel>>(), Arg.Any<Delta<int>>(), Arg.Any<Func<DatesLogicSaveModel, int>>(), Arg.Any<Func<DatesLogicSaveModel, int>>())
                 .ReturnsForAnyArgs(saveModel.DatesLogicDelta);

                f.Subject.ApplyChanges(eventRule, saveModel, new EventControlFieldsToUpdate());

                var updatedRule = eventRule.DatesLogic.Single();
                Assert.NotNull(updatedRule);
                Assert.Equal(sequence, updatedRule.Sequence);
                Assert.Equal(editedDatesLogic.RelativeCycle, updatedRule.RelativeCycle);
                Assert.Equal(inherit, updatedRule.IsInherited);
            }

            [Fact]
            public void DeletesDatesLogic()
            {
                var f = new DateEntryRulesFixture();

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build();
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build();
                var datesLogicDelete = new DatesLogicSaveModelBuilder {Inherited = 1}.For(eventRule).Build();
                var datesLogicDelete1 = new DatesLogicSaveModelBuilder {Inherited = 0}.For(eventRule).Build();
                var datesLogicDontDelete = new DatesLogicSaveModelBuilder {Inherited = 0}.For(eventRule).Build();
                eventRule.DatesLogic.Add(datesLogicDelete);
                eventRule.DatesLogic.Add(datesLogicDelete1);
                eventRule.DatesLogic.Add(datesLogicDontDelete);
                datesLogicDelete.OriginalHashKey = datesLogicDelete.HashKey();
                datesLogicDelete1.OriginalHashKey = datesLogicDelete1.HashKey();
                datesLogicDontDelete.OriginalHashKey = datesLogicDontDelete.HashKey();

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id};
                saveModel.DatesLogicDelta.Deleted.AddRange(new[] {datesLogicDelete, datesLogicDelete1});

                f.WorkflowEventInheritanceService.GetDelta(Arg.Any<Delta<DatesLogicSaveModel>>(), Arg.Any<Delta<int>>(), Arg.Any<Func<DatesLogicSaveModel, int>>(), Arg.Any<Func<DatesLogicSaveModel, int>>())
                 .ReturnsForAnyArgs(saveModel.DatesLogicDelta);

                f.Subject.ApplyChanges(eventRule, saveModel, new EventControlFieldsToUpdate());

                Assert.Equal(1, eventRule.DatesLogic.Count);
                Assert.Equal(datesLogicDontDelete.HashKey(), eventRule.DatesLogic.Single().HashKey());
            }

            [Fact]
            public void ThrowsErrorWhenAddingDuplicateDatesLogic()
            {
                var f = new DateEntryRulesFixture();

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build();
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build();
                var existing = new DatesLogicBuilder {Sequence = Fixture.Short()}.For(eventRule).Build();
                eventRule.DatesLogic.Add(existing);

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id};

                var datesLogic = new DatesLogicSaveModelBuilder().Build();
                datesLogic.CopyFrom(existing, false);
                saveModel.DatesLogicDelta.Added.Add(datesLogic);

                f.WorkflowEventInheritanceService.GetDelta(Arg.Any<Delta<DatesLogicSaveModel>>(), Arg.Any<Delta<int>>(), Arg.Any<Func<DatesLogicSaveModel, int>>(), Arg.Any<Func<DatesLogicSaveModel, int>>())
                 .ReturnsForAnyArgs(saveModel.DatesLogicDelta);

                Assert.Throws<InvalidOperationException>(() => f.Subject.ApplyChanges(eventRule, saveModel, new EventControlFieldsToUpdate()));
            }
        }

        public class SetChildInheritanceDeltaMethod
        {
            [Fact]
            public void SetsDateEntryRuleDelta()
            {
                var f = new DateEntryRulesFixture();
                var returnDelta = new Delta<int>();
                f.WorkflowEventInheritanceService.GetInheritDelta(Arg.Any<Func<Delta<int>>>(), Arg.Any<Func<bool, IEnumerable<int>>>()).ReturnsForAnyArgs(returnDelta);

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                f.Subject.SetChildInheritanceDelta(null, null, fieldsToUpdate);

                f.WorkflowEventInheritanceService.Received(1).GetInheritDelta(Arg.Any<Func<Delta<int>>>(), Arg.Any<Func<bool, IEnumerable<int>>>());
                Assert.Equal(returnDelta, fieldsToUpdate.DatesLogicDelta);
            }
        }

        public class RemoveInheritanceMethod
        {
            [Fact]
            public void BreaksInheritanceOnDateEntryRules()
            {
                var f = new DateEntryRulesFixture();

                var baseEvent = new Event(Fixture.Integer());

                var criteria = new CriteriaBuilder().Build();
                var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();
                criteria.ValidEvents.Add(eventRule);

                var existingDatesLogic = new DatesLogicBuilder {Sequence = Fixture.Short(), Inherited = 1}.For(eventRule).Build();
                eventRule.DatesLogic.Add(existingDatesLogic);

                var existingDatesLogic1 = new DatesLogicBuilder {Sequence = Fixture.Short(), Inherited = 1}.For(eventRule).Build();
                eventRule.DatesLogic.Add(existingDatesLogic1);

                var addedDatesLogicDontBreak = new DatesLogicBuilder {Sequence = Fixture.Short(), Inherited = 1}.For(eventRule).Build();
                eventRule.DatesLogic.Add(addedDatesLogicDontBreak);

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DatesLogicDelta.Added.Add(addedDatesLogicDontBreak.HashKey());
                fieldsToUpdate.DatesLogicDelta.Updated.Add(existingDatesLogic.HashKey());
                fieldsToUpdate.DatesLogicDelta.Deleted.Add(existingDatesLogic1.HashKey());

                f.Subject.RemoveInheritance(eventRule, fieldsToUpdate);
                Assert.False(existingDatesLogic.IsInherited);
                Assert.False(existingDatesLogic1.IsInherited);
                Assert.True(addedDatesLogicDontBreak.IsInherited);
            }
        }

        public class ResetMethod
        {
            [Fact]
            public void AddsIfNotExisting()
            {
                var f = new DateEntryRulesFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var dateEntryRule = new DatesLogic();
                DataFiller.Fill(dateEntryRule);
                parent.DatesLogic.Add(dateEntryRule);

                f.Subject.Reset(newValues, parent, criteria);

                var added = newValues.DatesLogicDelta.Added.First();
                Assert.Equal(dateEntryRule.HashKey(), added.HashKey());
                Assert.Empty(newValues.DatesLogicDelta.Updated);
                Assert.Empty(newValues.DatesLogicDelta.Deleted);
            }

            [Fact]
            public void DeletesIfNotInParent()
            {
                var f = new DateEntryRulesFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var dateEntryRule = new DatesLogic();
                DataFiller.Fill(dateEntryRule);
                criteria.DatesLogic.Add(dateEntryRule);

                f.Subject.Reset(newValues, parent, criteria);

                var deleted = newValues.DatesLogicDelta.Deleted.First();
                Assert.Equal(dateEntryRule.HashKey(), deleted.OriginalHashKey);
                Assert.Empty(newValues.DatesLogicDelta.Added);
                Assert.Empty(newValues.DatesLogicDelta.Updated);
            }

            [Fact]
            public void UpdatesIfExisting()
            {
                var f = new DateEntryRulesFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var dateEntryRule = new DatesLogic();
                DataFiller.Fill(dateEntryRule);
                parent.DatesLogic.Add(dateEntryRule);
                criteria.DatesLogic.Add(dateEntryRule);

                f.Subject.Reset(newValues, parent, criteria);

                var updated = newValues.DatesLogicDelta.Updated.First();
                Assert.Equal(dateEntryRule.HashKey(), updated.OriginalHashKey);
                Assert.Empty(newValues.DatesLogicDelta.Added);
                Assert.Empty(newValues.DatesLogicDelta.Deleted);
            }
        }
    }

    public class DateEntryRulesFixture : IFixture<DateEntryRules>
    {
        public DateEntryRulesFixture()
        {
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();

            Subject = new DateEntryRules(WorkflowEventInheritanceService);
        }

        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }
        public DateEntryRules Subject { get; }
    }
}