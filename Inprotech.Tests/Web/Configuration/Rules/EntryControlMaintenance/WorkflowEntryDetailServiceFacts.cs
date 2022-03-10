using System.Collections.Generic;
using System.Linq;
using AutoMapper;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance
{
    public class WorkflowEntryDetailServiceFacts : FactBase
    {
        public class ValidateChangeFunction : FactBase
        {
            [Fact]
            public void CallsValidatorMethods()
            {
                var dataEntry = new DataEntryTask();
                var changes = new WorkflowEntryControlSaveModel();
                var descriptionError = new ValidationError("Field", "Message");

                var f = new WorkflowEntryDetailServiceFixture(Db);
                f.DescriptionValidator.Validate(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>()).ReturnsForAnyArgs(descriptionError);

                var result = f.Subject.ValidateChange(dataEntry, changes).ToArray();
                f.DescriptionValidator.Received(1).Validate(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>());
                f.SectionMaintenances.First().Received(1).Validate(dataEntry, changes);

                Assert.NotEmpty(result);
                Assert.Equal(descriptionError, result.First());
            }

            [Fact]
            public void ReturnsWithoutErrorsIfValidUpdate()
            {
                var f = new WorkflowEntryDetailServiceFixture(Db);

                var result = f.Subject.ValidateChange(new DataEntryTask(), new WorkflowEntryControlSaveModel()).ToArray();

                Assert.Empty(result);
            }
        }

        public class UpdateEntryDetailFunctionInheritanceRelated : FactBase
        {
            [Theory]
            [InlineData("A new Entry - Updated", false, true)]
            [InlineData("A new & Entry()", false, false)]
            [InlineData("A new entry--", true, true)]
            [InlineData("A new entry", true, false)]
            public void BreakInheritanceFromParentIfRelavent(string newDesc, bool isSeparator, bool inheritanceIsBoken)
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();

                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 1)
                {
                    Description = "A new entry",
                    IsSeparator = isSeparator
                }.WithParentInheritance().Build().In(Db);

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = 1,
                    Description = newDesc,
                    ApplyToDescendants = false
                };

                f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                var updatedEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == f.CriteriaData.CriteriaChild1.Id);
                Assert.Equal(inheritanceIsBoken ? 0 : 1, updatedEntry.Inherited);
            }

            [Theory]
            [InlineData("A new Entry - Updated", false, true)]
            [InlineData("A new & Entry()", false, false)]
            [InlineData("A new entry--", true, true)]
            [InlineData("A new entry", true, false)]
            public void BreakInheritanceInChildrenIfNotApplyingDescriptionChangeToDescendents(string newDesc, bool isSeparator, bool inheritanceIsBoken)
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();

                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                {
                    Description = "A new entry",
                    IsSeparator = isSeparator
                }.WithParentInheritance().Build().In(Db);

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Description = newDesc,
                    ApplyToDescendants = false
                };

                f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask>
                {
                    entryToUpdate,
                    new DataEntryTaskBuilder(f.CriteriaData.Criteria, 2)
                    {
                        Description = "Existing Entry 1",
                        IsSeparator = isSeparator
                    }.WithParentInheritance().Build().In(Db),
                    new DataEntryTaskBuilder(f.CriteriaData.Criteria, 3)
                    {
                        Description = "An old Entry"
                    }.WithParentInheritance().Build().In(Db)
                };

                f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask>
                {
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 21)
                    {
                        Description = "A new entry",
                        IsSeparator = isSeparator
                    }.WithParentInheritance(entryToUpdate.Id).Build().In(Db)
                };
                f.CriteriaData.CriteriaChild2.DataEntryTasks = new List<DataEntryTask>
                {
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild2, 21)
                    {
                        Description = "A new entry",
                        IsSeparator = isSeparator
                    }.WithParentInheritance(entryToUpdate.Id).Build().In(Db)
                };

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);

                var entriesInChild1 = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == f.CriteriaData.CriteriaChild1.Id);
                Assert.Equal(inheritanceIsBoken ? 0 : 1, entriesInChild1.Inherited);

                var entriesInChild2 = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == f.CriteriaData.CriteriaChild2.Id);
                Assert.Equal(inheritanceIsBoken ? 0 : 1, entriesInChild2.Inherited);
            }

            [Theory]
            [InlineData(false, "A new entry", "A new Entry - Updated")]
            [InlineData(true, "A new entry", "A new Entry - Updated")]
            [InlineData(true, "##A###", "(*)")]
            public void BreakInheritanceIfCanNotApplyDescriptionChangeToDescendent(bool isSeparator, string existingDesc, string newDesc)
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria().WithUpdatedDescriptionUniqueness(false);

                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                {
                    Description = existingDesc,
                    UserInstruction = "Current Instruction",
                    IsSeparator = isSeparator
                }.WithParentInheritance().Build().In(Db);

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Description = newDesc,
                    UserInstruction = "Updated Instruction",
                    ApplyToDescendants = true
                };

                f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask>
                {
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 21)
                    {
                        Description = existingDesc,
                        UserInstruction = "Current Instruction",
                        IsSeparator = isSeparator
                    }.WithParentInheritance(entryToUpdate.Id).Build().In(Db),
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 22)
                    {
                        Description = newDesc,
                        UserInstruction = "Instruction",
                        IsSeparator = isSeparator
                    }.Build().In(Db)
                };

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);

                var entriesInChild1 = f.DbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == f.CriteriaData.CriteriaChild1.Id).OrderBy(_ => _.Id).ToArray();

                f.DescriptionValidator.Received(1).IsDescriptionUnique(f.CriteriaData.CriteriaChild1.Id, existingDesc, newDesc, isSeparator);

                Assert.Equal(0, entriesInChild1[0].Inherited);
                Assert.Equal(existingDesc, entriesInChild1[0].Description);
                Assert.Equal("Current Instruction", entriesInChild1[0].UserInstruction);

                Assert.Null(entriesInChild1[1].Inherited);
                Assert.Equal(newDesc, entriesInChild1[1].Description);
                Assert.Equal("Instruction", entriesInChild1[1].UserInstruction);
            }

            [Fact]
            public void AppliesFieldLevelUpdatesToChildEntriesIfApplyToDescendents()
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria().WithUpdatedDescriptionUniqueness(true);

                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                {
                    UserInstruction = "Instrution",
                    ShouldPoliceImmediately = true,
                    Description = "A new entry"
                }.Build().In(Db);

                var oldEntry = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 2)
                {
                    Description = "An old Entry"
                }.Build().In(Db);

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = 1,
                    UserInstruction = "New Instrution",
                    ShouldPoliceImmediate = false,
                    Description = "A new Entry",
                    ApplyToDescendants = true
                };

                f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask>
                {
                    entryToUpdate,
                    oldEntry
                };
                f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask>
                {
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 21)
                    {
                        UserInstruction = "Different Instrution",
                        ShouldPoliceImmediately = true,
                        Description = "A new entry"
                    }.WithParentInheritance(entryToUpdate.Id).Build().In(Db),
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 11)
                    {
                        Description = "An old Entry"
                    }.WithParentInheritance(oldEntry.Id).Build().In(Db)
                };

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                var updatedEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.Id == 21 && _.CriteriaId == f.CriteriaData.CriteriaChild1.Id);
                Assert.False(updatedEntry.ShouldPoliceImmediate);
                Assert.Equal("Different Instrution", updatedEntry.UserInstruction);
            }

            [Fact]
            public void ApppliesUpdatesToCurrentEntry()
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();
                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.CriteriaIndependent, 1)
                {
                    Description = "A new Entry",
                    UserInstruction = "Instruction",
                    ShouldPoliceImmediately = true
                }.Build().In(Db);
                var otherEntry = new DataEntryTaskBuilder(f.CriteriaData.CriteriaIndependent, 2)
                {
                    Description = "An old Entry"
                }.Build().In(Db);

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = 1,
                    UserInstruction = "New Instruction",
                    ShouldPoliceImmediate = false,
                    Description = "A new Entry"
                };

                f.CriteriaData.CriteriaIndependent.DataEntryTasks = new List<DataEntryTask>
                {
                    entryToUpdate,
                    otherEntry
                };

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                var updatedEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);

                Assert.False(updatedEntry.ShouldPoliceImmediate);
                Assert.Equal(updatedValues.UserInstruction, updatedEntry.UserInstruction);
            }

            [Fact]
            public void BreakRecordLevelInheritanceIfNotApplyingtoChildren()
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();

                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                {
                    Description = "A new entry"
                }.WithParentInheritance().BuildWithAvailableEvents(Db, "event1", "event2", "event3");

                var event1 = entryToUpdate.AvailableEvents.Single(_ => _.EventName == "event1");
                var event2 = entryToUpdate.AvailableEvents.Single(_ => _.EventName == "event2");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Description = "A new Entry",
                    ApplyToDescendants = false,
                    EntryEventDelta = new Delta<EntryEventDelta>
                    {
                        Updated = new List<EntryEventDelta> {new EntryEventDelta {PreviousEventId = event1.EventId, EventId = event1.EventId, DueAttribute = 1}},
                        Deleted = new List<EntryEventDelta> {new EntryEventDelta {EventId = event2.EventId}}
                    }
                };

                f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask>
                {
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 21)
                    {
                        Description = "A new entry"
                    }.WithParentInheritance(entryToUpdate.Id).BuildWithAvailableEvents(Db, "event1", "event2", "event3").In(Db)
                };

                f.CriteriaData.CriteriaChild2.DataEntryTasks = new List<DataEntryTask>
                {
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild2, 21)
                    {
                        Description = "A new entry"
                    }.WithParentInheritance(entryToUpdate.Id).BuildWithAvailableEvents(Db, "event1", "event2", "event3").In(Db)
                };

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);

                foreach (var fSectionMaintenance in f.SectionMaintenances) fSectionMaintenance.Received(2).RemoveInheritance(Arg.Any<DataEntryTask>(), Arg.Any<EntryControlFieldsToUpdate>());
            }

            [Fact]
            public void DoesNotApplyUpdatesToDescendentsIfNotApplingToDescendents()
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();
                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                {
                    UserInstruction = "Instrution",
                    ShouldPoliceImmediately = true,
                    Description = "A new entry"
                }.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = 1,
                    UserInstruction = "New Instrution",
                    ShouldPoliceImmediate = false,
                    Description = "A new Entry",
                    ApplyToDescendants = false
                };

                f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask>
                {
                    entryToUpdate,
                    new DataEntryTaskBuilder(f.CriteriaData.Criteria, 2)
                    {
                        Description = "An old Entry"
                    }.Build().In(Db)
                };
                f.CriteriaData.CriteriaChild2.DataEntryTasks = new List<DataEntryTask>
                {
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild2, 11)
                    {
                        UserInstruction = "Instrution",
                        ShouldPoliceImmediately = true,
                        Description = "A new entry"
                    }.WithParentInheritance().Build().In(Db),
                    new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild2, 31)
                    {
                        Description = "An old Entry"
                    }.WithParentInheritance().Build().In(Db)
                };

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                var updatedEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.Id == 11 && _.CriteriaId == f.CriteriaData.CriteriaChild2.Id);
                Assert.True(updatedEntry.ShouldPoliceImmediate);
                Assert.Equal("Instrution", updatedEntry.UserInstruction);
            }

            [Fact]
            public void ForwardCallsForDisplayReorderingAtCurrentLevel()
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();

                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.CriteriaIndependent)
                                    {
                                        Description = "blah"
                                    }
                                    .BuildWithAvailableEvents(Db, "apple,banana")
                                    .In(Db);

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    Description = "blah",
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(),
                        new EntryEventMovementsBase()
                    }
                };
                f.CriteriaData.CriteriaIndependent.DataEntryTasks.Add(entryToUpdate);

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);

                f.ReorderableSections.Single().Received(1).UpdateDisplayOrder(entryToUpdate, Arg.Any<EntryControlRecordMovements>());

                // no child entries, therefore no propagation
                f.ReorderableSections.Single().DidNotReceive().PropagateDisplayOrder(Arg.Any<EntryReorderSouce>(), Arg.Any<DataEntryTask>(), Arg.Any<EntryControlRecordMovements>());
            }

            [Fact]
            public void ForwardCallsForDisplayReorderingToDescendants()
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();

                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria)
                                    {
                                        Description = "blah"
                                    }
                                    .BuildWithAvailableEvents(Db, "apple", "banana")
                                    .In(Db);

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    Description = "blah",
                    ApplyToDescendants = true,
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(),
                        new EntryEventMovementsBase()
                    }
                };

                f.ReorderableSections.Single().PropagateDisplayOrder(null, null, null).ReturnsForAnyArgs(true);

                f.CriteriaData.Criteria.DataEntryTasks.Add(entryToUpdate);

                f.CriteriaData.CriteriaChild1
                 .DataEntryTasks.Add(
                                     new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1)
                                         {
                                             Description = "blah"
                                         }.WithParentInheritance(entryToUpdate.Id)
                                          .BuildWithAvailableEvents(Db, "apple", "banana", "coconut")
                                          .In(Db));

                f.CriteriaData.CriteriaGrandChild1
                 .DataEntryTasks.Add(
                                     new DataEntryTaskBuilder(f.CriteriaData.CriteriaGrandChild1)
                                         {
                                             Description = "blah"
                                         }.WithParentInheritance(f.CriteriaData.CriteriaChild1.DataEntryTasks.Single().Id)
                                          .BuildWithAvailableEvents(Db, "apple", "banana", "coconut", "durian")
                                          .In(Db));

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);

                f.ReorderableSections.Single().Received(1).UpdateDisplayOrder(entryToUpdate, Arg.Any<EntryControlRecordMovements>());

                f.ReorderableSections.Single().Received(1)
                 .PropagateDisplayOrder(Arg.Is<EntryReorderSouce>(_ => _.EntryEvents.Count() == 2),
                                        f.CriteriaData.CriteriaChild1.DataEntryTasks.Single(), Arg.Any<EntryControlRecordMovements>());

                f.ReorderableSections.Single().Received(1)
                 .PropagateDisplayOrder(Arg.Is<EntryReorderSouce>(_ => _.EntryEvents.Count() == 2),
                                        f.CriteriaData.CriteriaGrandChild1.DataEntryTasks.Single(), Arg.Any<EntryControlRecordMovements>());
            }

            [Fact]
            public void StopForwardCallsForDisplayReorderingToDescendantsIfReorderFails()
            {
                var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();

                var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria)
                                    {
                                        Description = "blah"
                                    }
                                    .BuildWithAvailableEvents(Db, "apple", "banana")
                                    .In(Db);

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    Description = "blah",
                    ApplyToDescendants = true,
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(),
                        new EntryEventMovementsBase()
                    }
                };

                f.CriteriaData.Criteria.DataEntryTasks.Add(entryToUpdate);

                f.CriteriaData.CriteriaChild1
                 .DataEntryTasks.Add(
                                     new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1)
                                         {
                                             Description = "blah"
                                         }.WithParentInheritance(entryToUpdate.Id)
                                          .BuildWithAvailableEvents(Db, "apple", "banana", "coconut")
                                          .In(Db));

                f.CriteriaData.CriteriaGrandChild1
                 .DataEntryTasks.Add(
                                     new DataEntryTaskBuilder(f.CriteriaData.CriteriaGrandChild1)
                                         {
                                             Description = "blah"
                                         }.WithParentInheritance(f.CriteriaData.CriteriaChild1.DataEntryTasks.Single().Id)
                                          .BuildWithAvailableEvents(Db, "apple", "banana", "coconut", "durian")
                                          .In(Db));

                f.ReorderableSections.Single()
                 .PropagateDisplayOrder(Arg.Any<EntryReorderSouce>(), f.CriteriaData.CriteriaChild1.DataEntryTasks.Single(), Arg.Any<EntryControlRecordMovements>())
                 .ReturnsForAnyArgs(false);

                f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);

                f.ReorderableSections.Single().Received(1).UpdateDisplayOrder(entryToUpdate, Arg.Any<EntryControlRecordMovements>());

                f.ReorderableSections.Single().Received(1)
                 .PropagateDisplayOrder(Arg.Is<EntryReorderSouce>(_ => _.EntryEvents.Count() == 2),
                                        f.CriteriaData.CriteriaChild1.DataEntryTasks.Single(), Arg.Any<EntryControlRecordMovements>());

                f.ReorderableSections.Single().DidNotReceive()
                 .PropagateDisplayOrder(Arg.Is<EntryReorderSouce>(_ => _.EntryEvents.Count() == 2),
                                        f.CriteriaData.CriteriaGrandChild1.DataEntryTasks.Single(), Arg.Any<EntryControlRecordMovements>());
            }
        }

        public class UpdateEntryDetailFunctionDataUpdation : FactBase
        {
            public class DetailSection : FactBase
            {
                [Fact]
                public void UpdateAppliedToChildrenConsideringFieldLevelInheritance()
                {
                    var f = new WorkflowEntryDetailServiceFixture(Db)
                            .WithCriteria()
                            .WithUpdatedDescriptionUniqueness(true);

                    var newTableCode = new TableCode(100, (short) TableTypes.FileLocation, "TableCode").In(Db);
                    var newNumberType = new NumberType {NumberTypeCode = "2", Name = "NumberType1"}.In(Db);
                    var newCaseStatus = new StatusBuilder().Build().In(Db);
                    var newRenewalStatus = new StatusBuilder().Build().In(Db);

                    var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                    {
                        Description = "A new Entry",
                        FileLocation = new TableCode(10, (short) TableTypes.FileLocation, "TableCode").In(Db),
                        NumberType = new NumberType {NumberTypeCode = "1", Name = "NumberType1"}.In(Db),
                        CaseStatus = new StatusBuilder().Build().In(Db),
                        RenewalStatus = new StatusBuilder().Build().In(Db),
                        ShouldPoliceImmediately = true,
                        AtleastOneEventFlag = false
                    }.Build().In(Db);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        Description = "A new Entry",
                        FileLocationId = newTableCode.Id,
                        OfficialNumberTypeId = newNumberType.NumberTypeCode,
                        CaseStatusCodeId = newCaseStatus.Id,
                        RenewalStatusId = newRenewalStatus.Id,
                        ShouldPoliceImmediate = false,
                        AtLeastOneFlag = true,
                        ApplyToDescendants = true
                    };

                    f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask>
                    {
                        new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 1)
                        {
                            Description = "A new Entry",
                            FileLocation = new TableCode(20, (short) TableTypes.FileLocation, "TableCode").In(Db),
                            NumberType = entryToUpdate.OfficialNumberType,
                            CaseStatus = entryToUpdate.CaseStatus,
                            RenewalStatus = entryToUpdate.RenewalStatus,
                            ShouldPoliceImmediately = true
                        }.WithParentInheritance(entryToUpdate.Id).Build().In(Db)
                    };

                    f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);

                    var updatedEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == f.CriteriaData.CriteriaChild1.Id);

                    Assert.Equal(updatedValues.OfficialNumberTypeId, updatedEntry.OfficialNumberTypeId);
                    Assert.Equal(updatedValues.CaseStatusCodeId, updatedEntry.CaseStatusCodeId);
                    Assert.Equal(updatedValues.RenewalStatusId, updatedEntry.RenewalStatusId);
                    Assert.False(updatedEntry.ShouldPoliceImmediate);
                    Assert.True(updatedEntry.AtLeastOneEventMustBeEntered);
                    Assert.Equal(20, updatedEntry.FileLocationId);
                }

                [Fact]
                public void UpdateAppliedToCurrent()
                {
                    var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();
                    var newTableCode = new TableCode(100, (short) TableTypes.FileLocation, "TableCode").In(Db);
                    var newNumberType = new NumberType {NumberTypeCode = "2", Name = "NumberType1"}.In(Db);
                    var newCaseStatus = new StatusBuilder().Build().In(Db);
                    var newRenewalStatus = new StatusBuilder().Build().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.CriteriaIndependent, 1)
                    {
                        Description = "A new Entry",
                        FileLocation = new TableCode(10, (short) TableTypes.FileLocation, "TableCode").In(Db),
                        NumberType = new NumberType {NumberTypeCode = "1", Name = "NumberType1"}.In(Db),
                        CaseStatus = new StatusBuilder().Build().In(Db),
                        RenewalStatus = new StatusBuilder().Build().In(Db),
                        ShouldPoliceImmediately = true,
                        AtleastOneEventFlag = true
                    }.Build().In(Db);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        Description = "A new Entry",
                        FileLocationId = newTableCode.Id,
                        OfficialNumberTypeId = newNumberType.NumberTypeCode,
                        CaseStatusCodeId = newCaseStatus.Id,
                        RenewalStatusId = newRenewalStatus.Id,
                        ShouldPoliceImmediate = false,
                        AtLeastOneFlag = false
                    };

                    f.CriteriaData.CriteriaIndependent.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                    var updatedEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);

                    Assert.Equal(updatedValues.FileLocationId, updatedEntry.FileLocationId);
                    Assert.Equal(updatedValues.OfficialNumberTypeId, updatedEntry.OfficialNumberTypeId);
                    Assert.Equal(updatedValues.CaseStatusCodeId, updatedEntry.CaseStatusCodeId);
                    Assert.Equal(updatedValues.RenewalStatusId, updatedEntry.RenewalStatusId);
                    Assert.False(updatedEntry.ShouldPoliceImmediate);
                    Assert.Equal(0, updatedEntry.AtLeastOneFlag);
                }
            }

            public class DisplayConditionsSection : FactBase
            {
                [Fact]
                public void UpdateAppliedToChildrenConsideringFieldLevelInheritance()
                {
                    var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria().WithUpdatedDescriptionUniqueness(true);
                    var newTableCode = new TableCode(100, (short) TableTypes.FileLocation, "TableCode").In(Db);
                    var newNumberType = new NumberType {NumberTypeCode = "2", Name = "NumberType1"}.In(Db);
                    var eventIds = new[] {1, 2, 3};

                    var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                    {
                        Description = "A new Entry",
                        FileLocation = new TableCode(10, (short) TableTypes.FileLocation, "TableCode").In(Db),
                        NumberType = new NumberType {NumberTypeCode = "1", Name = "NumberType1"}.In(Db),
                        ShouldPoliceImmediately = true,
                        DisplayEventNo = eventIds[0],
                        HideEventNo = eventIds[1],
                        DimEventNo = eventIds[2]
                    }.Build().In(Db);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        Description = "A new Entry",
                        FileLocationId = newTableCode.Id,
                        OfficialNumberTypeId = newNumberType.NumberTypeCode,
                        ShouldPoliceImmediate = false,
                        ApplyToDescendants = true,
                        DisplayEventNo = eventIds[0] * 10,
                        HideEventNo = eventIds[1] * 10,
                        DimEventNo = eventIds[2] * 10
                    };

                    f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask>
                    {
                        new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 1)
                        {
                            Description = "A new Entry",
                            FileLocation = new TableCode(20, (short) TableTypes.FileLocation, "TableCode").In(Db),
                            NumberType = entryToUpdate.OfficialNumberType,
                            ShouldPoliceImmediately = true,
                            DisplayEventNo = eventIds[0],
                            HideEventNo = eventIds[1],
                            DimEventNo = eventIds[2]
                        }.WithParentInheritance(entryToUpdate.Id).Build().In(Db)
                    };

                    f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                    var updatedChildEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == f.CriteriaData.CriteriaChild1.Id);

                    Assert.Equal(updatedValues.OfficialNumberTypeId, updatedChildEntry.OfficialNumberTypeId);
                    Assert.False(updatedChildEntry.ShouldPoliceImmediate);
                    Assert.Equal(20, updatedChildEntry.FileLocationId);
                    Assert.Equal(updatedValues.DisplayEventNo, updatedChildEntry.DisplayEventNo);
                    Assert.Equal(updatedValues.HideEventNo, updatedChildEntry.HideEventNo);
                    Assert.Equal(updatedValues.DimEventNo, updatedChildEntry.DimEventNo);
                }

                [Fact]
                public void UpdateAppliedToCurrent()
                {
                    var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria().WithUpdatedDescriptionUniqueness(true);
                    var newTableCode = new TableCode(100, (short) TableTypes.FileLocation, "TableCode").In(Db);
                    var newNumberType = new NumberType {NumberTypeCode = "2", Name = "NumberType1"}.In(Db);
                    var eventIds = new[] {1, 2, 3};

                    var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.CriteriaIndependent, 1)
                    {
                        Description = "A new Entry",
                        FileLocation = new TableCode(10, (short) TableTypes.FileLocation, "TableCode").In(Db),
                        NumberType = new NumberType {NumberTypeCode = "1", Name = "NumberType1"}.In(Db),
                        ShouldPoliceImmediately = true,
                        DisplayEventNo = eventIds[0],
                        HideEventNo = eventIds[1],
                        DimEventNo = eventIds[2]
                    }.Build().In(Db);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        Description = "A new Entry",
                        FileLocationId = newTableCode.Id,
                        OfficialNumberTypeId = newNumberType.NumberTypeCode,
                        ShouldPoliceImmediate = false,
                        DisplayEventNo = eventIds[0] * 10,
                        HideEventNo = eventIds[1] * 10,
                        DimEventNo = eventIds[2] * 10
                    };

                    f.CriteriaData.CriteriaIndependent.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                    var updatedEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);

                    Assert.Equal(updatedValues.FileLocationId, updatedValues.FileLocationId);
                    Assert.Equal(updatedValues.OfficialNumberTypeId, updatedEntry.OfficialNumberTypeId);
                    Assert.False(updatedEntry.ShouldPoliceImmediate);
                    Assert.Equal(updatedValues.DisplayEventNo, updatedEntry.DisplayEventNo);
                    Assert.Equal(updatedValues.HideEventNo, updatedEntry.HideEventNo);
                    Assert.Equal(updatedValues.DimEventNo, updatedEntry.DimEventNo);
                }

                [Fact]
                public void UpdateNotAppliedToChildrenIfAnyOfChildValueIsDifferent()
                {
                    var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria().WithUpdatedDescriptionUniqueness(true);
                    var newTableCode = new TableCode(100, (short) TableTypes.FileLocation, "TableCode").In(Db);
                    var newNumberType = new NumberType {NumberTypeCode = "2", Name = "NumberType1"}.In(Db);
                    var eventIds = new[] {1, 2, 3};

                    var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                    {
                        Description = "A new Entry",
                        FileLocation = new TableCode(10, (short) TableTypes.FileLocation, "TableCode").In(Db),
                        NumberType = new NumberType {NumberTypeCode = "1", Name = "NumberType1"}.In(Db),
                        ShouldPoliceImmediately = true,
                        DisplayEventNo = eventIds[0],
                        HideEventNo = eventIds[1],
                        DimEventNo = eventIds[2]
                    }.Build().In(Db);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        Description = "A new Entry",
                        FileLocationId = newTableCode.Id,
                        OfficialNumberTypeId = newNumberType.NumberTypeCode,
                        ShouldPoliceImmediate = false,
                        ApplyToDescendants = true,
                        DisplayEventNo = eventIds[0] * 10,
                        HideEventNo = eventIds[1] * 10,
                        DimEventNo = eventIds[2] * 10
                    };

                    f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask>
                    {
                        new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 1)
                        {
                            Description = "A new Entry",
                            FileLocation = new TableCode(20, (short) TableTypes.FileLocation, "TableCode").In(Db),
                            NumberType = entryToUpdate.OfficialNumberType,
                            ShouldPoliceImmediately = true,
                            DisplayEventNo = eventIds[0],
                            HideEventNo = eventIds[1],
                            DimEventNo = eventIds[2] + 1
                        }.WithParentInheritance(entryToUpdate.Id).Build().In(Db)
                    };

                    f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                    var updatedChildEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == f.CriteriaData.CriteriaChild1.Id);

                    Assert.Equal(updatedValues.OfficialNumberTypeId, updatedChildEntry.OfficialNumberTypeId);
                    Assert.False(updatedChildEntry.ShouldPoliceImmediate);
                    Assert.Equal(20, updatedChildEntry.FileLocationId);
                    Assert.Equal(eventIds[0], updatedChildEntry.DisplayEventNo);
                    Assert.Equal(eventIds[1], updatedChildEntry.HideEventNo);
                    Assert.Equal(eventIds[2] + 1, updatedChildEntry.DimEventNo);
                }
            }

            public class SectionMaintenance : FactBase
            {
                [Fact]
                public void CallsSectionMaintenanceRemoveInheritanceMethod()
                {
                    var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();
                    var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                    {
                        Description = "A new Entry"
                    }.Build().In(Db);
                    f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var childEntryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 1)
                    {
                        Description = "A new Entry"
                    }.WithParentInheritance(entryToUpdate.Id).Build().In(Db);

                    f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask> {childEntryToUpdate};

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        Description = "A new Entry",
                        ApplyToDescendants = false
                    };

                    f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                    f.SectionMaintenances.First().DidNotReceive().SetDeltaForUpdate(childEntryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());
                    f.SectionMaintenances.Last().DidNotReceive().SetDeltaForUpdate(childEntryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());
                    f.SectionMaintenances.First().DidNotReceive().ApplyChanges(childEntryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());
                    f.SectionMaintenances.Last().DidNotReceive().ApplyChanges(childEntryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());

                    f.SectionMaintenances.First().Received(1).RemoveInheritance(childEntryToUpdate, Arg.Any<EntryControlFieldsToUpdate>());
                    f.SectionMaintenances.Last().Received(1).RemoveInheritance(childEntryToUpdate, Arg.Any<EntryControlFieldsToUpdate>());

                    f.SectionMaintenances.First().Received(1).ApplyChanges(entryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());
                    f.SectionMaintenances.Last().Received(1).ApplyChanges(entryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());
                }

                [Fact]
                public void CallsSectionMaintenancesApplyMethod()
                {
                    var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria().WithUpdatedDescriptionUniqueness(true);
                    var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                    {
                        Description = "A new Entry"
                    }.Build().In(Db);
                    f.CriteriaData.Criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var childEntryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.CriteriaChild1, 1)
                    {
                        Description = "A new Entry"
                    }.WithParentInheritance(entryToUpdate.Id).Build().In(Db);

                    f.CriteriaData.CriteriaChild1.DataEntryTasks = new List<DataEntryTask> {childEntryToUpdate};

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        Description = "A new Entry",
                        ApplyToDescendants = true
                    };

                    f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);
                    f.SectionMaintenances.First().Received(1).SetDeltaForUpdate(childEntryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());
                    f.SectionMaintenances.Last().Received(1).SetDeltaForUpdate(childEntryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());

                    f.SectionMaintenances.First().Received(1).ApplyChanges(childEntryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());
                    f.SectionMaintenances.Last().Received(1).ApplyChanges(childEntryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());

                    f.SectionMaintenances.First().Received(1).ApplyChanges(entryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());
                    f.SectionMaintenances.Last().Received(1).ApplyChanges(entryToUpdate, updatedValues, Arg.Any<EntryControlFieldsToUpdate>());
                }
            }

            public class ResetInheritance : FactBase
            {
                [Fact]
                public void KeepsInheritanceWhenResettingInheritanceAndDescriptionChanged()
                {
                    var f = new WorkflowEntryDetailServiceFixture(Db).WithCriteria();
                    var entryToUpdate = new DataEntryTaskBuilder(f.CriteriaData.Criteria, 1)
                    {
                        Description = "An existing Entry",
                        Inherited = 1,
                        ParentCriteriaId = Fixture.Integer(),
                        ParentEntryId = Fixture.Short()
                    }.Build().In(Db);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        Description = "An existing Entry $_#",
                        ResetInheritance = true
                    };

                    f.Subject.UpdateEntryDetail(entryToUpdate, updatedValues);

                    Assert.True(entryToUpdate.IsInherited);
                    Assert.NotNull(entryToUpdate.ParentCriteriaId);
                    Assert.NotNull(entryToUpdate.ParentEntryId);
                }
            }
        }

        class WorkflowEntryDetailServiceFixture : IFixture<WorkflowEntryDetailService>
        {
            public WorkflowEntryDetailServiceFixture(InMemoryDbContext db)
            {
                DbContext = db;
                DescriptionValidator = Substitute.For<IDescriptionValidator>();
                Mapper = new Mapper(new MapperConfiguration(cfg =>
                {
                    cfg.AddProfile(new EntryControlMaintenanceProfile());
                    cfg.CreateMissingTypeMaps = true;
                }));
                SectionMaintenances = new[] {Substitute.For<ISectionMaintenance>(), Substitute.For<ISectionMaintenance>()};
                ReorderableSections = new[] {Substitute.For<IReorderableSection>()};
                Inheritance = Substitute.For<IInheritance>();
                Subject = new WorkflowEntryDetailService(DbContext, Mapper, DescriptionValidator, SectionMaintenances, ReorderableSections, Inheritance);
            }

            IMapper Mapper { get; }

            public IDescriptionValidator DescriptionValidator { get; }
            public IEnumerable<ISectionMaintenance> SectionMaintenances { get; }

            public IEnumerable<IReorderableSection> ReorderableSections { get; }

            public InMemoryDbContext DbContext { get; }

            public CriteriaData CriteriaData { get; private set; }

            public IInheritance Inheritance { get; }

            public WorkflowEntryDetailService Subject { get; }

            public WorkflowEntryDetailServiceFixture WithCriteria()
            {
                var criteria = new CriteriaBuilder().Build().In(DbContext);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(DbContext);
                var criteriaChild2 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(DbContext);
                var criteriaGrandChild1 = new CriteriaBuilder {ParentCriteriaId = criteriaChild1.Id}.Build().In(DbContext);
                var criteriaIndependent = new CriteriaBuilder().Build().In(DbContext);

                CriteriaData = new CriteriaData
                {
                    Criteria = criteria,
                    CriteriaChild1 = criteriaChild1,
                    CriteriaChild2 = criteriaChild2,
                    CriteriaGrandChild1 = criteriaGrandChild1,
                    CriteriaIndependent = criteriaIndependent
                };

                Inheritance.GetChildren(criteria.Id).Returns(new[] {criteriaChild1, criteriaChild2});
                Inheritance.GetChildren(criteriaChild1.Id).Returns(new[] {criteriaGrandChild1});
                Inheritance.GetChildren(criteriaIndependent.Id).Returns(new Criteria[] { });

                Inheritance.GetParent(criteriaChild1.Id).Returns(criteria);
                Inheritance.GetParent(criteriaChild2.Id).Returns(criteria);
                Inheritance.GetParent(criteriaGrandChild1.Id).Returns(criteriaChild1);
                Inheritance.GetParent(criteriaIndependent.Id).Returns((Criteria) null);
                return this;
            }

            public WorkflowEntryDetailServiceFixture WithUpdatedDescriptionUniqueness(bool isUnique)
            {
                DescriptionValidator.IsDescriptionUnique(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(isUnique);
                return this;
            }
        }

        class CriteriaData
        {
            public Criteria Criteria { get; set; }
            public Criteria CriteriaChild1 { get; set; }
            public Criteria CriteriaChild2 { get; set; }
            public Criteria CriteriaGrandChild1 { get; set; }
            public Criteria CriteriaIndependent { get; set; }
        }
    }
}