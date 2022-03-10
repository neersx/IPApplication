using System;
using System.Linq;
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
    public class DueDateCalcFacts
    {
        public class ValidateMethod
        {
            [Theory]
            [InlineData("ADD", "A", 1, "W", 1, 1, false)]
            [InlineData("ADD", null, 1, "W", 1, 1, true)]
            [InlineData("ADD", "A", null, "W", 1, 1, true)]
            [InlineData("ADD", "A", 1, null, 1, 1, true)]
            [InlineData("ADD", "A", 1, "W", null, 1, true)]
            [InlineData("ADD", "A", 1, "W", 1, null, true)]
            [InlineData("EDIT", "A", 1, "W", 1, 1, false)]
            [InlineData("EDIT", null, 1, "W", 1, 1, true)]
            [InlineData("EDIT", "A", null, "W", 1, 1, true)]
            [InlineData("EDIT", "A", 1, null, 1, 1, true)]
            [InlineData("EDIT", "A", 1, "W", null, 1, true)]
            [InlineData("EDIT", "A", 1, "W", 1, null, true)]
            public void ChecksMandatoryFieldsOnDueDateCalcs(string addOrEdit, string @operator, int? period, string periodType, int? relCycle, int? toCycle, bool shouldHaveError)
            {
                var f = new DueDateCalcFixture();

                var eventControl = new ValidEventBuilder().Build();
                var dueDateCalcSave = new DueDateCalcSaveModelBuilder {FromEventId = Fixture.Integer()}.For(eventControl).Build();
                dueDateCalcSave.Operator = @operator;
                dueDateCalcSave.Period = (short?) period;
                dueDateCalcSave.PeriodType = periodType;
                dueDateCalcSave.RelativeCycle = (short?) relCycle;
                dueDateCalcSave.Cycle = (short?) toCycle;
                var delta = new Delta<DueDateCalcSaveModel>();
                if (addOrEdit == "ADD")
                {
                    delta.Added.Add(dueDateCalcSave);
                }
                else
                {
                    delta.Updated.Add(dueDateCalcSave);
                }

                var result = f.Subject.Validate(new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Added = new[] {dueDateCalcSave}}
                });

                if (shouldHaveError)
                {
                    Assert.NotEmpty(result);
                }
                else
                {
                    Assert.Empty(result);
                }
            }

            [Theory]
            [InlineData("E")]
            [InlineData("1")]
            [InlineData("2")]
            [InlineData("3")]
            public void PeriodIsNotRequiredForSpecificPeriodType(string type)
            {
                var f = new DueDateCalcFixture();
                var model = new WorkflowEventControlSaveModel();
                model.DueDateCalcDelta.Added.Add(new DueDateCalcSaveModel
                {
                    Operator = "1",
                    FromEventId = 2,
                    RelativeCycle = 3,
                    PeriodType = type,

                    Period = null,
                    Cycle = 1
                });

                Assert.Empty(f.Subject.Validate(model));
            }

            [Fact]
            public void IsValidIfAllMandatoryFieldsFilledIn()
            {
                var f = new DueDateCalcFixture();
                var model = new WorkflowEventControlSaveModel();
                model.DueDateCalcDelta.Added.Add(new DueDateCalcSaveModel
                {
                    Operator = "1",
                    FromEventId = 2,
                    RelativeCycle = 3,
                    PeriodType = "4",
                    Period = 5,
                    Cycle = 1
                });

                Assert.Empty(f.Subject.Validate(model));
            }
        }

        public class SetChildInheritanceDeltaMethod
        {
            [Fact]
            public void SetsDueDateCalcsDeltaFromService()
            {
                var f = new DueDateCalcFixture();
                var criteria = new CriteriaBuilder().Build();
                var baseEvent = new Event(Fixture.Integer());
                var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();
                var newValues = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                var returnDelta = new Delta<int>();
                f.DueDateCalcService.GetChildInheritanceDelta(eventRule, newValues, fieldsToUpdate).Returns(returnDelta);
                f.Subject.SetChildInheritanceDelta(eventRule, newValues, fieldsToUpdate);

                f.DueDateCalcService.Received(1).GetChildInheritanceDelta(eventRule, newValues, fieldsToUpdate);
                Assert.Equal(returnDelta, fieldsToUpdate.DueDateCalcsDelta);
            }
        }

        public class ApplyChangesMethod
        {
            [Fact]
            public void GetsDeltaAndCallsApply()
            {
                var f = new DueDateCalcFixture();

                var baseEvent = new Event(Fixture.Integer());

                var criteria = new CriteriaBuilder().Build();
                var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();

                var ddcDelta = new Delta<DueDateCalcSaveModel>();
                var newValues = new WorkflowEventControlSaveModel();
                newValues.DueDateCalcDelta = ddcDelta;
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                f.WorkflowEventInheritanceService.GetDelta(newValues.DueDateCalcDelta, fieldsToUpdate.DueDateCalcsDelta, Arg.Any<Func<DueDateCalcSaveModel, int>>(), Arg.Any<Func<DueDateCalcSaveModel, int>>()).ReturnsForAnyArgs(ddcDelta);
                f.Subject.ApplyChanges(eventRule, newValues, fieldsToUpdate);
                f.DueDateCalcService.Received(1).ApplyDueDateCalcChanges(newValues.OriginatingCriteriaId, eventRule, ddcDelta, false);
            }
        }

        public class RemoveInheritanceMethod
        {
            [Fact]
            public void BreaksInheritanceOnDueDateCalc()
            {
                var f = new DueDateCalcFixture();

                var baseEvent = new Event(Fixture.Integer());

                var criteria = new CriteriaBuilder().Build();
                var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();
                criteria.ValidEvents.Add(eventRule);

                var existingDueDateCalc = new DueDateCalcBuilder {Sequence = Fixture.Short(), Inherited = 1}.For(eventRule).Build();
                eventRule.DueDateCalcs.Add(existingDueDateCalc);

                var existingDueDateCalc1 = new DueDateCalcBuilder {Sequence = Fixture.Short(), Inherited = 1}.For(eventRule).Build();
                eventRule.DueDateCalcs.Add(existingDueDateCalc1);

                var addedDueDateCalcsDontBreak = new DueDateCalcBuilder {Sequence = Fixture.Short(), Inherited = 1}.For(eventRule).Build();
                eventRule.DueDateCalcs.Add(addedDueDateCalcsDontBreak);

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DueDateCalcsDelta.Added.Add(addedDueDateCalcsDontBreak.HashKey());
                fieldsToUpdate.DueDateCalcsDelta.Updated.Add(existingDueDateCalc.HashKey());
                fieldsToUpdate.DueDateCalcsDelta.Deleted.Add(existingDueDateCalc1.HashKey());

                f.Subject.RemoveInheritance(eventRule, fieldsToUpdate);
                Assert.False(existingDueDateCalc.IsInherited);
                Assert.False(existingDueDateCalc1.IsInherited);
                Assert.True(addedDueDateCalcsDontBreak.IsInherited);
            }
        }

        public class ResetMethod
        {
            [Fact]
            public void AddsIfNotExisting()
            {
                var f = new DueDateCalcFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var dueDateCalc = new DueDateCalc();
                DataFiller.Fill(dueDateCalc);
                dueDateCalc.Comparison = null;
                dueDateCalc.JurisdictionId = null;
                parent.DueDateCalcs.Add(dueDateCalc);

                f.Subject.Reset(newValues, parent, criteria);

                var added = newValues.DueDateCalcDelta.Added.First();
                Assert.Equal(dueDateCalc.HashKey(), added.HashKey());
                Assert.Empty(newValues.DueDateCalcDelta.Updated);
                Assert.Empty(newValues.DueDateCalcDelta.Deleted);
            }

            [Fact]
            public void DeletesIfNotInParent()
            {
                var f = new DueDateCalcFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var dueDateCalc = new DueDateCalc();
                DataFiller.Fill(dueDateCalc);
                dueDateCalc.Comparison = null;
                dueDateCalc.JurisdictionId = null;
                criteria.DueDateCalcs.Add(dueDateCalc);

                f.Subject.Reset(newValues, parent, criteria);

                var deleted = newValues.DueDateCalcDelta.Deleted.First();
                Assert.Equal(dueDateCalc.HashKey(), deleted.OriginalHashKey);
                Assert.Empty(newValues.DueDateCalcDelta.Added);
                Assert.Empty(newValues.DueDateCalcDelta.Updated);
            }

            [Fact]
            public void UpdatesIfExisting()
            {
                var f = new DueDateCalcFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var dueDateCalc = new DueDateCalc();
                DataFiller.Fill(dueDateCalc);
                dueDateCalc.Comparison = null;
                dueDateCalc.JurisdictionId = null;
                parent.DueDateCalcs.Add(dueDateCalc);
                criteria.DueDateCalcs.Add(dueDateCalc);

                f.Subject.Reset(newValues, parent, criteria);

                var updated = newValues.DueDateCalcDelta.Updated.First();
                Assert.Equal(dueDateCalc.HashKey(), updated.OriginalHashKey);
                Assert.Empty(newValues.DueDateCalcDelta.Added);
                Assert.Empty(newValues.DueDateCalcDelta.Deleted);
            }
        }
    }

    public class DueDateCalcFixture : IFixture<DueDateCalcMaintenance>
    {
        public DueDateCalcFixture()
        {
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
            DueDateCalcService = Substitute.For<IDueDateCalcService>();

            Subject = new DueDateCalcMaintenance(WorkflowEventInheritanceService, DueDateCalcService);
        }

        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }
        public IDueDateCalcService DueDateCalcService { get; }
        public DueDateCalcMaintenance Subject { get; }
    }
}