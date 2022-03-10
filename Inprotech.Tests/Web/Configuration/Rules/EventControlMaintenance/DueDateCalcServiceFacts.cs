using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
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
    public class DueDateCalcServiceFacts
    {
        public class SetChildInheritanceDeltaMethod : FactBase
        {
            [Fact]
            public void DoesNotSetAddedDueDatesWithACountryWhenChildHasACountry()
            {
                var f = new DueDateCalcServiceFixture(Db);
                var childCriteria = new CriteriaBuilder {CountryId = Fixture.String()}.Build().In(Db);
                var baseEvent = new EventBuilder().Build();
                var childEvent = new ValidEventBuilder {Inherited = true}.For(childCriteria, baseEvent).Build();

                var shouldNotAdd = new DueDateCalcBuilder().For(childEvent).Build();
                shouldNotAdd.JurisdictionId = Fixture.String();

                var shouldAdd = new DueDateCalcBuilder().For(childEvent).Build();
                shouldAdd.JurisdictionId = null;

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DueDateCalcsDelta.Added.Add(shouldNotAdd.HashKey());
                fieldsToUpdate.DueDateCalcsDelta.Added.Add(shouldAdd.HashKey());

                var saveModel = new WorkflowEventControlSaveModel();

                var shouldNotAddSaveModel = new DueDateCalcSaveModel();
                shouldNotAddSaveModel.CopyFrom(shouldNotAdd);
                saveModel.DueDateCalcDelta.Added.Add(shouldNotAddSaveModel);

                var shouldAddSaveModel = new DueDateCalcSaveModel();
                shouldAddSaveModel.CopyFrom(shouldAdd);
                saveModel.DueDateCalcDelta.Added.Add(shouldAddSaveModel);

                f.WorkflowEventInheritanceService.GetInheritDelta(Arg.Any<Func<Delta<int>>>(), Arg.Any<Func<bool, IEnumerable<int>>>()).ReturnsForAnyArgs(fieldsToUpdate.DueDateCalcsDelta);

                var result = f.Subject.GetChildInheritanceDelta(childEvent, saveModel, fieldsToUpdate);

                Assert.Equal(1, result.Added.Count);
                Assert.True(result.Added.Contains(shouldAdd.HashKey()));
                Assert.False(result.Added.Contains(shouldNotAdd.HashKey()));
            }

            [Fact]
            public void SetsDueDateCalcDelta()
            {
                var f = new DueDateCalcServiceFixture(Db);
                var returnDelta = new Delta<int>();
                f.WorkflowEventInheritanceService.GetInheritDelta(Arg.Any<Func<Delta<int>>>(), Arg.Any<Func<bool, IEnumerable<int>>>()).ReturnsForAnyArgs(returnDelta);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var baseEvent = new Event(Fixture.Integer());
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id, DueDateCalcDelta = new Delta<DueDateCalcSaveModel>()};
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                var result = f.Subject.GetChildInheritanceDelta(eventRule, saveModel, fieldsToUpdate);

                f.WorkflowEventInheritanceService.Received(1).GetInheritDelta(Arg.Any<Func<Delta<int>>>(), Arg.Any<Func<bool, IEnumerable<int>>>());
                Assert.Equal(returnDelta, result);
            }
        }

        public class ApplyDueDateCalcChangesMethod : FactBase
        {
            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public void AddsOrInheritsDueDateCalcSpecifiedInFieldsToUpdate(bool inherit)
            {
                var f = new DueDateCalcServiceFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var sequence = Fixture.Short();
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = sequence}.For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = inherit ? Fixture.Integer() : criteria.Id, DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Added = new List<DueDateCalcSaveModel>()}};
                var newDueDateCalcSave = new DueDateCalcSaveModelBuilder().For(eventRule).Build();
                saveModel.DueDateCalcDelta.Added.Add(newDueDateCalcSave);

                f.Subject.ApplyDueDateCalcChanges(saveModel.OriginatingCriteriaId, eventRule, saveModel.DueDateCalcDelta, false);

                Assert.Equal(2, eventRule.DueDateCalcs.Count);
                var addedRule = eventRule.DueDateCalcs.SingleOrDefault(_ => _.HashKey() == newDueDateCalcSave.HashKey());
                Assert.NotNull(addedRule);
                Assert.Equal(sequence + 1, addedRule.Sequence);
                Assert.Equal(inherit, addedRule.IsInherited);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public void UpdatesOrInheritsDueDateCalcs(bool inherit)
            {
                var f = new DueDateCalcServiceFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var sequence = Fixture.Short();
                var existingDueDateCalc = new DueDateCalcBuilder {Sequence = sequence, Inherited = 1}.For(eventRule).Build();
                eventRule.DueDateCalcs.Add(existingDueDateCalc);

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = inherit ? Fixture.Integer() : criteria.Id, DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Updated = new List<DueDateCalcSaveModel>()}};
                var editedDueDateCalc = new DueDateCalcSaveModelBuilder().For(eventRule).Build();
                editedDueDateCalc.OriginalHashKey = existingDueDateCalc.HashKey();
                saveModel.DueDateCalcDelta.Updated.Add(editedDueDateCalc);

                Assert.NotEqual(eventRule.DueDateCalcs.Single().HashKey(), editedDueDateCalc.HashKey());

                f.Subject.ApplyDueDateCalcChanges(saveModel.OriginatingCriteriaId, eventRule, saveModel.DueDateCalcDelta, false);

                var updatedRule = eventRule.DueDateCalcs.Single();
                Assert.NotNull(updatedRule);
                Assert.Equal(sequence, updatedRule.Sequence);
                Assert.Equal(editedDueDateCalc.RelativeCycle, updatedRule.RelativeCycle);
                Assert.Equal(editedDueDateCalc.FromEventId, updatedRule.FromEventId);
                Assert.Equal(editedDueDateCalc.Cycle, updatedRule.Cycle);
                Assert.Equal(editedDueDateCalc.JurisdictionId, updatedRule.JurisdictionId);
                Assert.Equal(inherit, updatedRule.IsInherited);
            }

            [Fact]
            public void RemovesInheritedChildDueDateCalcs()
            {
                var f = new DueDateCalcServiceFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var sequence = Fixture.Short();
                var dueDateCalcToBeDeleted = new DueDateCalcBuilder {Sequence = sequence, Inherited = 1}.For(eventRule).Build().In(Db);
                eventRule.DueDateCalcs.Add(dueDateCalcToBeDeleted);

                var dueDateCalcNotInherited = new DueDateCalcBuilder {Sequence = ++sequence}.For(eventRule).Build().In(Db);
                eventRule.DueDateCalcs.Add(dueDateCalcNotInherited);

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = Fixture.Integer(), DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Deleted = new List<DueDateCalcSaveModel>()}};

                var delete1 = new DueDateCalcSaveModelBuilder().For(eventRule).Build();
                delete1.OriginalHashKey = dueDateCalcToBeDeleted.HashKey();

                var delete2 = new DueDateCalcSaveModelBuilder().For(eventRule).Build();
                delete2.OriginalHashKey = dueDateCalcToBeDeleted.HashKey();

                saveModel.DueDateCalcDelta.Deleted.Add(delete1);
                saveModel.DueDateCalcDelta.Deleted.Add(delete2);

                f.WorkflowEventInheritanceService.GetDelta(Arg.Any<Delta<DueDateCalcSaveModel>>(), Arg.Any<Delta<int>>(), Arg.Any<Func<DueDateCalcSaveModel, int>>(), Arg.Any<Func<DueDateCalcSaveModel, int>>()).ReturnsForAnyArgs(saveModel.DueDateCalcDelta);

                f.Subject.ApplyDueDateCalcChanges(saveModel.OriginatingCriteriaId, eventRule, saveModel.DueDateCalcDelta, false);

                Assert.Null(eventRule.DueDateCalcs.SingleOrDefault(_ => _.Sequence == dueDateCalcToBeDeleted.Sequence));
                Assert.NotNull(eventRule.DueDateCalcs.SingleOrDefault(_ => _.Sequence == dueDateCalcNotInherited.Sequence));
            }

            [Fact]
            public void RemovesParentDueDateCalcs()
            {
                var f = new DueDateCalcServiceFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var sequence = Fixture.Short();
                var dueDateCalcToBeDeleted = new DueDateCalcBuilder {Sequence = sequence}.For(eventRule).Build().In(Db);
                eventRule.DueDateCalcs.Add(dueDateCalcToBeDeleted);

                var existingDueDateCalc = new DueDateCalcBuilder {Sequence = ++sequence}.For(eventRule).Build().In(Db);
                eventRule.DueDateCalcs.Add(existingDueDateCalc);

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id, DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Deleted = new List<DueDateCalcSaveModel>()}};

                var delete = new DueDateCalcSaveModelBuilder().For(eventRule).Build();
                delete.OriginalHashKey = dueDateCalcToBeDeleted.HashKey();

                saveModel.DueDateCalcDelta.Deleted.Add(delete);

                f.WorkflowEventInheritanceService.GetDelta(Arg.Any<Delta<DueDateCalcSaveModel>>(), Arg.Any<Delta<int>>(), Arg.Any<Func<DueDateCalcSaveModel, int>>(), Arg.Any<Func<DueDateCalcSaveModel, int>>()).ReturnsForAnyArgs(saveModel.DueDateCalcDelta);

                f.Subject.ApplyDueDateCalcChanges(saveModel.OriginatingCriteriaId, eventRule, saveModel.DueDateCalcDelta, false);

                Assert.Null(eventRule.DueDateCalcs.SingleOrDefault(_ => _.Sequence == dueDateCalcToBeDeleted.Sequence));
                Assert.NotNull(eventRule.DueDateCalcs.SingleOrDefault(_ => _.Sequence == existingDueDateCalc.Sequence));
            }

            [Theory]
            [ClassData(typeof(DueDateTheoryData))]
            public void CheckForDuplicateDueDateCalc(bool expectedResult, Func<InMemoryDbContext, DueDateTheoryData.DueDateData>dataFunc)
            {
                var f = new DueDateCalcServiceFixture(Db);

                var data = dataFunc(Db);

                if (!data.ExpectedResult)
                {
                    f.Subject.ApplyDueDateCalcChanges(data.Existing.CriteriaId, data.Existing.ValidEvent, data.Updates.DueDateCalcDelta, false);

                    var resultCount = Db.Set<ValidEvent>().Single().DueDateCalcs.Count;
                    Assert.Equal(2, resultCount);
                }
                else
                {
                    Assert.Throws<InvalidOperationException>(() => f.Subject.ApplyDueDateCalcChanges(data.Existing.CriteriaId, data.Existing.ValidEvent,data.Updates.DueDateCalcDelta, false));
                }
            }

            public class DueDateTheoryData : IEnumerable<object[]>
            {
                public class DueDateData
                {
                    public bool ExpectedResult { get; set; }
                    public DueDateCalc Existing { get; set; }
                    public WorkflowEventControlSaveModel Updates { get; set; }
                }

                public IEnumerator<object[]> GetEnumerator()
                {
                    yield return new object[]
                    {
                        true,
                        new Func<InMemoryDbContext, DueDateData>(db =>
                        {
                            var data = CreateData(db);
                            data.ExpectedResult = false;
                            data.Updates.DueDateCalcDelta.Added.First().PeriodType = "M";
                            return data;
                        })
                    };

                    yield return new object[]
                    {
                        true,
                        new Func<InMemoryDbContext, DueDateData>(db =>
                        {
                            var data = CreateData(db);
                            data.ExpectedResult = false;
                            data.Updates.DueDateCalcDelta.Added.First().Period = 98;
                            return data;
                        })
                    };

                    yield return new object[]
                    {
                        true,
                        new Func<InMemoryDbContext, DueDateData>(db =>
                        {
                            var data = CreateData(db);
                            data.ExpectedResult = false;
                            data.Updates.DueDateCalcDelta.Added.First().PeriodType = "M";
                            return data;
                        })
                    };
                    yield return new object[]
                    {
                        true,
                        new Func<InMemoryDbContext, DueDateData>(db =>
                        {
                            var data = CreateData(db);
                            data.ExpectedResult = false;
                            data.Updates.DueDateCalcDelta.Added.First().Cycle = 99;
                            return data;
                        })
                    };
                    yield return new object[]
                    {
                        true,
                        new Func<InMemoryDbContext, DueDateData>(db =>
                        {
                            var data = CreateData(db);
                            data.ExpectedResult = false;
                            data.Updates.DueDateCalcDelta.Added.First().JurisdictionId = "AU";
                            return data;
                        })
                    };
                    yield return new object[]
                    {
                        true,
                        new Func<InMemoryDbContext, DueDateData>(db =>
                        {
                            var data = CreateData(db);
                            data.ExpectedResult = false;
                            data.Updates.DueDateCalcDelta.Added.First().FromEventId = 1900;
                            return data;
                        })
                    };
                    yield return new object[]
                    {
                        true,
                        new Func<InMemoryDbContext, DueDateData>(db =>
                        {
                            var data = CreateData(db);
                            data.ExpectedResult = false;
                            data.Updates.DueDateCalcDelta.Added.First().RelativeCycle = 9;
                            return data;
                        })
                    };
                    yield return new object[]
                    {
                        true,
                        new Func<InMemoryDbContext, DueDateData>(db =>
                        {
                            var data = CreateData(db);
                            data.ExpectedResult = true;
                            return data;
                        })
                    };
                }

                DueDateData CreateData(InMemoryDbContext dbContext)
                {
                    var baseEvent = new Event(Fixture.Integer());
                    var criteria = new CriteriaBuilder().Build().In(dbContext);
                    var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(dbContext);
                    var sequence = Fixture.Short();
                    var dueDateCalc = new DueDateCalcBuilder {Sequence = sequence}.For(eventRule).Build().In(dbContext);
                    eventRule.DueDateCalcs.Add(dueDateCalc);
                    dueDateCalc.ValidEvent = eventRule;

                    var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id, DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Added = new List<DueDateCalcSaveModel>()}};
                    var newDueDateCalcSave = new DueDateCalcSaveModelBuilder().For(eventRule).Build();
                    newDueDateCalcSave.CopyFrom(dueDateCalc);
                    saveModel.DueDateCalcDelta.Added.Add(newDueDateCalcSave);

                    return new DueDateData {Existing = dueDateCalc, Updates = saveModel};
                }

                IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
            }
        }
    }

    public class DueDateCalcServiceFixture : IFixture<IDueDateCalcService>
    {
        public DueDateCalcServiceFixture(InMemoryDbContext db)
        {
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
            Subject = new DueDateCalcService(WorkflowEventInheritanceService, db);
        }

        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }
        public IDueDateCalcService Subject { get; }
    }
}