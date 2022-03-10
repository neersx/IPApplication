using System;
using System.Collections.Generic;
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
    public class DateComparisonFacts
    {
        public class Validate : FactBase
        {
            [Theory]
            [InlineData(null, (short) 1, "EX")]
            [InlineData(1, null, "EX")]
            [InlineData(1, (short) 1, null)]
            public void ReturnsInvalidWhenMandatoryFieldMissing(int? fromEventId, short? relativeCycle, string comparison)
            {
                var f = new DateComparisonFixture();
                var saveModel = new WorkflowEventControlSaveModel();
                saveModel.DateComparisonDelta.Added.Add(new DateComparisonSaveModel
                {
                    Comparison = comparison,
                    FromEventId = fromEventId,
                    RelativeCycle = relativeCycle
                });

                Assert.NotEmpty(f.Subject.Validate(saveModel));
            }

            [Fact]
            public void CompareCycleRequiredWithCompareEventB()
            {
                var f = new DateComparisonFixture();
                var saveModel = new WorkflowEventControlSaveModel();

                saveModel.DateComparisonDelta.Added.Add(new DateComparisonSaveModel
                {
                    Comparison = "=",
                    FromEventId = 1,
                    RelativeCycle = 1,
                    CompareEventId = 2,
                    CompareCycle = 2
                });

                Assert.Empty(f.Subject.Validate(saveModel));

                saveModel.DateComparisonDelta.Added.Add(new DateComparisonSaveModel
                {
                    Comparison = "=",
                    FromEventId = 1,
                    RelativeCycle = 1,
                    CompareEventId = 2
                });

                Assert.NotEmpty(f.Subject.Validate(saveModel));
            }

            [Fact]
            public void ReturnsValidIfCompareDateOrSystemDate()
            {
                var f = new DateComparisonFixture();
                var saveModel = new WorkflowEventControlSaveModel();

                saveModel.DateComparisonDelta.Added.Add(new DateComparisonSaveModel
                {
                    Comparison = "=",
                    FromEventId = 1,
                    RelativeCycle = 1,
                    CompareSystemDate = true
                });

                saveModel.DateComparisonDelta.Added.Add(new DateComparisonSaveModel
                {
                    Comparison = "=",
                    FromEventId = 1,
                    RelativeCycle = 1,
                    CompareDate = DateTime.Now
                });

                Assert.Empty(f.Subject.Validate(saveModel));
            }

            [Fact]
            public void ReturnsValidWhenComparisonOperatorIsExistsOrNonExists()
            {
                var f = new DateComparisonFixture();

                var saveModel = new WorkflowEventControlSaveModel();
                saveModel.DateComparisonDelta.Added.Add(new DateComparisonSaveModel
                {
                    Comparison = "EX",
                    FromEventId = 1,
                    RelativeCycle = 1
                });

                saveModel.DateComparisonDelta.Updated.Add(new DateComparisonSaveModel
                {
                    Comparison = "NE",
                    FromEventId = 1,
                    RelativeCycle = 1
                });

                Assert.Empty(f.Subject.Validate(saveModel));
            }
        }

        public class SetChildInheritanceDeltaMethod
        {
            [Fact]
            public void SetsDateComparisonDeltaFromService()
            {
                var f = new DateComparisonFixture();
                var criteria = new CriteriaBuilder().Build();
                var baseEvent = new Event(Fixture.Integer());
                var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();
                var newValues = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                var returnDelta = new Delta<int>();
                f.WorkflowEventInheritanceService.GetInheritDelta(Arg.Any<Func<Delta<int>>>(), Arg.Any<Func<bool, IEnumerable<int>>>()).ReturnsForAnyArgs(returnDelta);
                f.Subject.SetChildInheritanceDelta(eventRule, newValues, fieldsToUpdate);

                f.WorkflowEventInheritanceService.Received(1).GetInheritDelta(Arg.Any<Func<Delta<int>>>(), Arg.Any<Func<bool, IEnumerable<int>>>());
                Assert.Equal(returnDelta, fieldsToUpdate.DateComparisonDelta);
            }
        }

        public class ApplyChangesMethod
        {
            [Fact]
            public void GetsDeltaAndCallsApply()
            {
                var f = new DateComparisonFixture();

                var baseEvent = new Event(Fixture.Integer());

                var criteria = new CriteriaBuilder().Build();
                var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();

                var dcDelta = new Delta<DateComparisonSaveModel>();
                var newValues = new WorkflowEventControlSaveModel();
                newValues.DateComparisonDelta = dcDelta;
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                f.WorkflowEventInheritanceService.GetDelta(newValues.DateComparisonDelta, fieldsToUpdate.DateComparisonDelta, Arg.Any<Func<DateComparisonSaveModel, int>>(), Arg.Any<Func<DateComparisonSaveModel, int>>()).ReturnsForAnyArgs(dcDelta);
                f.Subject.ApplyChanges(eventRule, newValues, fieldsToUpdate);
                f.DueDateCalcService.Received(1).ApplyDueDateCalcChanges(newValues.OriginatingCriteriaId, eventRule, Arg.Any<Delta<DueDateCalcSaveModel>>(), false);
            }
        }

        public class RemoveInheritanceMethod
        {
            [Fact]
            public void BreaksInheritanceOnDateComparison()
            {
                var f = new DateComparisonFixture();

                var baseEvent = new Event(Fixture.Integer());

                var criteria = new CriteriaBuilder().Build();
                var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();
                criteria.ValidEvents.Add(eventRule);

                var existingDateComparison = new DueDateCalcBuilder {Sequence = Fixture.Short(), Inherited = 1}.For(eventRule).Build();
                existingDateComparison.Comparison = "=";
                eventRule.DueDateCalcs.Add(existingDateComparison);

                var existingDateComparison1 = new DueDateCalcBuilder {Sequence = Fixture.Short(), Inherited = 1}.For(eventRule).Build();
                existingDateComparison1.Comparison = "=";
                eventRule.DueDateCalcs.Add(existingDateComparison1);

                var addedDateComparisonsDontBreak = new DueDateCalcBuilder {Sequence = Fixture.Short(), Inherited = 1}.For(eventRule).Build();
                addedDateComparisonsDontBreak.Comparison = "=";
                eventRule.DueDateCalcs.Add(addedDateComparisonsDontBreak);

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DateComparisonDelta.Added.Add(addedDateComparisonsDontBreak.HashKey());
                fieldsToUpdate.DateComparisonDelta.Updated.Add(existingDateComparison.HashKey());
                fieldsToUpdate.DateComparisonDelta.Deleted.Add(existingDateComparison1.HashKey());

                f.Subject.RemoveInheritance(eventRule, fieldsToUpdate);
                Assert.False(existingDateComparison.IsInherited);
                Assert.False(existingDateComparison1.IsInherited);
                Assert.True(addedDateComparisonsDontBreak.IsInherited);
            }
        }

        public class ResetMethod
        {
            [Fact]
            public void AddsIfNotExisting()
            {
                var f = new DateComparisonFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var dateComparison = new DateComparisonSaveModel();
                DataFiller.Fill(dateComparison);
                dateComparison.Comparison = Fixture.String();
                dateComparison.JurisdictionId = null;
                parent.DueDateCalcs.Add(dateComparison);

                f.Subject.Reset(newValues, parent, criteria);

                var added = newValues.DateComparisonDelta.Added.First();
                Assert.Equal(dateComparison.HashKey(), added.HashKey());
                Assert.Empty(newValues.DateComparisonDelta.Updated);
                Assert.Empty(newValues.DateComparisonDelta.Deleted);
            }

            [Fact]
            public void DeletesIfNotInParent()
            {
                var f = new DateComparisonFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var dateComparison = new DateComparisonSaveModel();
                DataFiller.Fill(dateComparison);
                dateComparison.Comparison = Fixture.String();
                dateComparison.JurisdictionId = null;
                criteria.DueDateCalcs.Add(dateComparison);

                f.Subject.Reset(newValues, parent, criteria);

                var deleted = newValues.DateComparisonDelta.Deleted.First();
                Assert.Equal(dateComparison.HashKey(), deleted.OriginalHashKey);
                Assert.Empty(newValues.DateComparisonDelta.Added);
                Assert.Empty(newValues.DateComparisonDelta.Updated);
            }

            [Fact]
            public void UpdatesIfExisting()
            {
                var f = new DateComparisonFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var dateComparison = new DateComparisonSaveModel();
                DataFiller.Fill(dateComparison);
                dateComparison.Comparison = Fixture.String();
                dateComparison.JurisdictionId = null;
                parent.DueDateCalcs.Add(dateComparison);
                criteria.DueDateCalcs.Add(dateComparison);

                f.Subject.Reset(newValues, parent, criteria);

                var updated = newValues.DateComparisonDelta.Updated.First();
                Assert.Equal(dateComparison.HashKey(), updated.OriginalHashKey);
                Assert.Empty(newValues.DateComparisonDelta.Added);
                Assert.Empty(newValues.DateComparisonDelta.Deleted);
            }
        }
    }

    public class DateComparisonFixture : IFixture<DateComparison>
    {
        public DateComparisonFixture()
        {
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
            DueDateCalcService = Substitute.For<IDueDateCalcService>();

            Subject = new DateComparison(WorkflowEventInheritanceService, DueDateCalcService);
        }

        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }
        public IDueDateCalcService DueDateCalcService { get; }
        public DateComparison Subject { get; }
    }
}