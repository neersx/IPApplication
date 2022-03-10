using System.Collections.Generic;
using System.Linq;
using AutoMapper;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance
{
    public class StepMaintenanceFacts
    {
        public class ValidateMethod : FactBase
        {
            [Fact]
            public void CallsValidate()
            {
                var d = new DataEntryTaskBuilder().Build();
                var w = new WorkflowEntryControlSaveModel();
                var e = new ValidationError(Fixture.String(), Fixture.String());
                var f = new StepMaintenanceFixture(Db);

                f.WorkflowEntryStepsService.Validate(d, w).Returns(new[] {e});

                var r = f.Subject.Validate(d, w);

                Assert.Contains(e, r);
            }
        }

        public class SetDeltaForUpdateMethod
        {
            public class ForAdd : FactBase
            {
                readonly DataEntryTask _child = new DataEntryTaskBuilder().Build();
                readonly WorkflowEntryControlSaveModel _model = new WorkflowEntryControlSaveModel();
                readonly DataEntryTask _parent = new DataEntryTaskBuilder().Build();

                [Fact]
                public void EnsureAdditionIsPropagatedInChild()
                {
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmChecklist", "C", "checklist", "1")
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_parent, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.SetDeltaForUpdate(_child, _model, update);

                    Assert.Equal(1, update.StepsDelta.Added.Count);
                }

                [Fact]
                public void ShouldNotConsiderItemsAlreadyPresentSteps()
                {
                    var checklist = new TopicControl("frmChecklist");
                    checklist.Filters.Add(new TopicControlFilter(StepCategoryCodes.ChecklistTypeKey, "1"));

                    _child.AddWorkflowWizardStep(checklist);

                    var stepDelta1 = new StepDelta("frmChecklist", "C", "checklist", "1");
                    var stepDelta2 = new StepDelta("frmChecklist", "C", "checklist", "2");
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            stepDelta1,
                            stepDelta2
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_parent, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.SetDeltaForUpdate(_child, _model, update);

                    Assert.Equal(stepDelta2.HashCode(), update.StepsDelta.Added.Single().NewHashCode);
                }

                [Fact]
                public void ShouldNotConsiderItemsNotInImmediateParent()
                {
                    var stepDelta1 = new StepDelta("frmChecklist", "C", "checklist", "1");
                    var stepDelta2 = new StepDelta("frmChecklist", "C", "checklist", "2");
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            stepDelta1,
                            stepDelta2
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_parent, _model);

                    /* during propagation, some items may be removed due to them colliding as duplicate */
                    update.StepsDelta.Added = update.StepsDelta.Added.Except(new[] {update.StepsDelta.Added.ElementAt(0)}).ToArray();

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.SetDeltaForUpdate(_child, _model, update);

                    Assert.Equal(stepDelta2.HashCode(), update.StepsDelta.Added.Single().NewHashCode);

                    Assert.Empty(update.StepsRemoveInheritanceFor);
                }
            }

            public class ForUpdate : FactBase
            {
                readonly DataEntryTask _child = new DataEntryTaskBuilder().Build();
                readonly WorkflowEntryControlSaveModel _model = new WorkflowEntryControlSaveModel();
                readonly DataEntryTask _parent = new DataEntryTaskBuilder().Build();

                [Fact]
                public void PreventPropagationIfInChildUninherited()
                {
                    var original = _parent.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    var childOriginal = _child.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    childOriginal.IsInherited = false;

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Updated = new[]
                        {
                            new StepDelta("frmChecklist", "C", "checklist", "1")
                            {
                                Id = original.Id
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_parent, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.SetDeltaForUpdate(_child, _model, update);

                    Assert.Empty(update.StepsDelta.Updated);
                }

                [Fact]
                public void PreventPropagationIfSimilarStepExistsInChild()
                {
                    var original = _parent.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    var childOriginal = _child.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    childOriginal.IsInherited = true;

                    /* this will collide on propagation and the change relates to a key element of the row. */
                    _child.WithStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "1"));

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Updated = new[]
                        {
                            new StepDelta("frmChecklist", "C", "checklist", "1")
                            {
                                Id = original.Id
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_parent, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.SetDeltaForUpdate(_child, _model, update);

                    Assert.Empty(update.StepsDelta.Updated);

                    Assert.Equal(childOriginal.HashCode(), update.StepsRemoveInheritanceFor.Single());
                }

                [Fact]
                public void ShouldNotConsiderItemsNotInImmediateParent()
                {
                    var changedScreentip = Fixture.String();

                    var original1 = _parent.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "1"));

                    var original2 = _parent.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    var childOriginal1 = _child.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "1"));

                    var childOriginal2 = _child.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    childOriginal1.IsInherited = true;

                    childOriginal2.IsInherited = true;

                    var stepDeltaChecklist1 = new StepDelta("frmChecklist", "C", "checklist", "1")
                    {
                        Id = original1.Id,
                        ScreenTip = Fixture.String()
                    };

                    var stepDeltaChecklist2 = new StepDelta("frmChecklist", "C", "checklist", "2")
                    {
                        Id = original2.Id,
                        ScreenTip = changedScreentip
                    };

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Updated = new[]
                        {
                            stepDeltaChecklist1,
                            stepDeltaChecklist2
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_parent, _model);

                    /* during propagation, some items may be removed due to them colliding as duplicate */
                    update.StepsDelta.Updated = update.StepsDelta.Updated.Except(new[] {update.StepsDelta.Updated.ElementAt(0)}).ToArray();

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.SetDeltaForUpdate(_child, _model, update);

                    Assert.Equal(stepDeltaChecklist2.HashCode(), update.StepsDelta.Updated.Single().OriginalHashCode.Value);

                    Assert.Empty(update.StepsRemoveInheritanceFor);
                }
            }

            public class ForDelete : FactBase
            {
                readonly DataEntryTask _child = new DataEntryTaskBuilder().Build();
                readonly WorkflowEntryControlSaveModel _model = new WorkflowEntryControlSaveModel();
                readonly DataEntryTask _parent = new DataEntryTaskBuilder().Build();

                [Fact]
                public void PreventPropagationIfInChildUninherited()
                {
                    var original = _parent.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    var childOriginal = _child.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    childOriginal.IsInherited = false;

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Deleted = new[]
                        {
                            new StepDelta("frmChecklist", "C", "checklist", "2")
                            {
                                Id = original.Id
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_parent, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.SetDeltaForUpdate(_child, _model, update);

                    Assert.Empty(update.StepsDelta.Deleted);
                }

                [Fact]
                public void ShouldNotConsiderItemsNotInImmediateParent()
                {
                    var original1 = _parent.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "1"));

                    var original2 = _parent.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    var childOriginal1 = _child.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "1"));

                    var childOriginal2 = _child.BuildStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "2"));

                    childOriginal1.IsInherited = true;

                    childOriginal2.IsInherited = true;

                    var stepDeltaChecklist1 = new StepDelta("frmChecklist", "C", "checklist", "1")
                    {
                        Id = original1.Id
                    };

                    var stepDeltaChecklist2 = new StepDelta("frmChecklist", "C", "checklist", "2")
                    {
                        Id = original2.Id
                    };
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Deleted = new[]
                        {
                            stepDeltaChecklist1,
                            stepDeltaChecklist2
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_parent, _model);

                    /* during propagation, some items may be removed due to them colliding as duplicate */
                    update.StepsDelta.Deleted = update.StepsDelta.Deleted.Except(new[] {update.StepsDelta.Deleted.ElementAt(0)}).ToArray();

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.SetDeltaForUpdate(_child, _model, update);

                    Assert.Equal(stepDeltaChecklist2.HashCode(), update.StepsDelta.Deleted.Single().OriginalHashCode);

                    Assert.Empty(update.StepsRemoveInheritanceFor);
                }
            }
        }

        public class ApplyChangesMethod
        {
            public class ForUpdate : FactBase
            {
                readonly DataEntryTask _entry = new DataEntryTaskBuilder().Build();
                readonly WorkflowEntryControlSaveModel _model = new WorkflowEntryControlSaveModel();

                [Theory]
                [InlineData("frmCaseEventSummry", "A", "CreateActionKey", "action")]
                [InlineData("frmCaseHistory", "A", "CreateActionKey", "action")]
                [InlineData("frmCaseTextSummry", "R", "CaseRelationKey", "relationship")]
                [InlineData("frmCheckList", "C", "ChecklistTypeKey", "checklist")]
                [InlineData("frmDesignation", "F", "CountryFlag", "designationStage")]
                [InlineData("frmDocuments", "A", "CreateActionKey", "action")]
                [InlineData("frmEDECaseResolutionMain", "A", "CreateActionKey", "action")]
                [InlineData("frmEDECaseResolutionNames", "P", "NameGroupKey", "nameTypeGroup")]
                [InlineData("frmNameGrp", "P", "NameGroupKey", "nameTypeGroup")]
                [InlineData("frmNames", "N", "NameTypeKey", "nameType")]
                [InlineData("frmOfficialNo", "O", "NumberTypeKeys", "numberType")]
                [InlineData("frmRelationships", "M", "CaseRelationKey", "relationship")]
                [InlineData("frmText", "T", "TextTypeKey", "textType")]
                public void ApplyUpdateToTargetSingleFilter(string name, string type, string filterName, string filterType)
                {
                    var originalFilterValue = Fixture.String();
                    var changedFilterValue = Fixture.String();

                    var target = _entry.BuildStep(Db, name, new TopicControlFilter(filterName, originalFilterValue));

                    target.IsMandatory = false;
                    target.ScreenTip = Fixture.String();
                    target.Title = Fixture.String();
                    target.IsInherited = true;

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Updated = new[]
                        {
                            new StepDelta(name, type, filterType, changedFilterValue)
                            {
                                Id = target.Id,
                                ScreenTip = "ABC",
                                Title = "DEF",
                                IsMandatory = true
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    Assert.Equal("DEF", target.Title);
                    Assert.Equal("ABC", target.ScreenTip);
                    Assert.True(target.IsMandatory);
                    Assert.Equal(1, target.Filters.Count);
                    Assert.Equal(filterName, target.Filters.Single().FilterName);
                    Assert.Equal(changedFilterValue, target.Filters.Single().FilterValue);
                }

                [Theory]
                [InlineData("has both existing filter")]
                [InlineData("has just one existing filter")]
                [InlineData("no existing filters")]
                public void ApplyUpdateToTargetBothFilters(string condition)
                {
                    var originalNameTypeKey = Fixture.String();
                    var originalTextTypeKey = Fixture.String();

                    var changedNameTypeKey = Fixture.String();
                    var changedTextTypeKey = Fixture.String();

                    var target = _entry.BuildStep(Db, "frmNameText",
                                                  new TopicControlFilter("NameTypeKey", originalNameTypeKey),
                                                  new TopicControlFilter("TextTypeKey", originalTextTypeKey));

                    switch (condition)
                    {
                        case "has both existing filter":
                            break;
                        case "has just one existing filter":
                            target.Filters.Remove(target.Filters.Last());
                            break;
                        case "no existing filters":
                            target.Filters.Clear();
                            break;
                    }

                    target.IsMandatory = false;
                    target.ScreenTip = Fixture.String();
                    target.Title = Fixture.String();
                    target.IsInherited = true;

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Updated = new[]
                        {
                            new StepDelta("frmNameText", "X", "nameType", changedNameTypeKey, "textType", changedTextTypeKey)
                            {
                                Id = target.Id,
                                ScreenTip = "ABC",
                                Title = "DEF",
                                IsMandatory = true
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    Assert.Equal("DEF", target.Title);
                    Assert.Equal("ABC", target.ScreenTip);
                    Assert.True(target.IsMandatory);
                    Assert.Equal(2, target.Filters.Count);
                    Assert.Equal("NameTypeKey", target.Filters.First().FilterName);
                    Assert.Equal(changedNameTypeKey, target.Filters.First().FilterValue);
                    Assert.Equal("TextTypeKey", target.Filters.Last().FilterName);
                    Assert.Equal(changedTextTypeKey, target.Filters.Last().FilterValue);
                }

                [Fact]
                public void ApplyUpdateToTargetNoFilters()
                {
                    var target = _entry.BuildStep(Db, "frmGeneral");

                    target.IsMandatory = false;
                    target.ScreenTip = Fixture.String();
                    target.Title = Fixture.String();

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Updated = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                            {
                                Id = target.Id,
                                ScreenTip = "ABC",
                                Title = "DEF",
                                IsMandatory = true
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    Assert.Equal("DEF", target.Title);
                    Assert.Equal("ABC", target.ScreenTip);
                    Assert.True(target.IsMandatory);
                    Assert.Empty(target.Filters);
                }

                [Fact]
                public void ResetsInheritanceWhenResetting()
                {
                    var step1 = _entry.BuildStep(Db, "frmGeneral");
                    var step2 = _entry.BuildStep(Db, "frmBudget");
                    step1.IsInherited = false;
                    step2.IsInherited = false;

                    _model.CriteriaId = _entry.CriteriaId;
                    _model.Id = _entry.Id;
                    _model.ResetInheritance = true;
                    _model.StepsDelta.Updated.Add(new StepDelta(step1.Name, "G") {Id = step1.Id});
                    _model.StepsDelta.Updated.Add(new StepDelta(step2.Name, "G") {Id = step2.Id});

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    Assert.True(step1.IsInherited);
                    Assert.True(step2.IsInherited);
                }

                [Fact]
                public void ShouldBreakInheritanceForAnyIdentifiedCollisions()
                {
                    var step1 = _entry.BuildStep(Db, "frmGeneral");
                    var step2 = _entry.BuildStep(Db, "frmBudget");
                    var step3 = _entry.BuildStep(Db, "frmAttributes");
                    var step4 = _entry.BuildStep(Db, "frmCaseDates");

                    step1.IsInherited = true;
                    step2.IsInherited = true;
                    step3.IsInherited = true;
                    step4.IsInherited = true;

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    update.StepsRemoveInheritanceFor.Add(step2.HashCode());
                    update.StepsRemoveInheritanceFor.Add(step4.HashCode());

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    Assert.True(step1.IsInherited);
                    Assert.True(step3.IsInherited);
                    Assert.False(step2.IsInherited);
                    Assert.False(step4.IsInherited);
                }

                [Fact]
                public void ShouldBreakInheritanceWhenChangingInheritedEntry()
                {
                    var target = _entry.BuildStep(Db, "frmGeneral");

                    _model.CriteriaId = _entry.CriteriaId; /* indicates this is the parent */
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Updated = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                            {
                                Id = target.Id
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    Assert.False(target.IsInherited);
                }

                [Fact]
                public void ShouldNotBreakInheritanceWhenPropagatingToChangeToChild()
                {
                    var target = _entry.BuildStep(Db, "frmGeneral");

                    target.IsInherited = true;

                    _model.CriteriaId = Fixture.Integer();
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Updated = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                            {
                                Id = target.Id
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    Assert.True(target.IsInherited);
                }
            }

            public class ForDelete : FactBase
            {
                public ForDelete()
                {
                    _entry = new DataEntryTaskBuilder().Build().In(Db);
                    _model = new WorkflowEntryControlSaveModel();
                }

                readonly DataEntryTask _entry;
                readonly WorkflowEntryControlSaveModel _model;

                [Fact]
                public void DeleteStepsMentionedInStepDelta()
                {
                    var actionStep = _entry.BuildStep(Db, "frmCaseEventSummry", new TopicControlFilter("CreateActionKey", "A"));
                    var checklistStep1 = _entry.BuildStep(Db, "frmCheckList", new TopicControlFilter("ChecklistTypeKey", "C1"));
                    var checklistStep2 = _entry.BuildStep(Db, "frmCheckList", new TopicControlFilter("ChecklistTypeKey", "C2"));

                    var deleteDelta = new EntryControlFieldsToUpdate(_entry, _model);

                    deleteDelta.StepsDelta.Deleted.Add(new StepHashes(checklistStep1.HashCode()));
                    deleteDelta.StepsDelta.Deleted.Add(new StepHashes(actionStep.HashCode()));

                    var subject = new StepMaintenanceFixture(Db).Subject;
                    subject.ApplyChanges(_entry, _model, deleteDelta);

                    var topicControls = Db.Set<TopicControl>().ToArray();
                    Assert.Single(topicControls);
                    Assert.Equal(checklistStep2.Id, topicControls.Single().Id);
                }
            }

            public class ForAdditions : FactBase
            {
                readonly DataEntryTask _entry = new DataEntryTaskBuilder().Build();
                readonly WorkflowEntryControlSaveModel _model = new WorkflowEntryControlSaveModel();

                [Theory]
                [InlineData("frmCaseEventSummry", "A", "CreateActionKey", "action")]
                [InlineData("frmCaseHistory", "A", "CreateActionKey", "action")]
                [InlineData("frmCaseTextSummry", "R", "CaseRelationKey", "relationship")]
                [InlineData("frmCheckList", "C", "ChecklistTypeKey", "checklist")]
                [InlineData("frmDesignation", "F", "CountryFlag", "designationStage")]
                [InlineData("frmDocuments", "A", "CreateActionKey", "action")]
                [InlineData("frmEDECaseResolutionMain", "A", "CreateActionKey", "action")]
                [InlineData("frmEDECaseResolutionNames", "P", "NameGroupKey", "nameTypeGroup")]
                [InlineData("frmNameGrp", "P", "NameGroupKey", "nameTypeGroup")]
                [InlineData("frmNames", "N", "NameTypeKey", "nameType")]
                [InlineData("frmOfficialNo", "O", "NumberTypeKeys", "numberType")]
                [InlineData("frmRelationships", "M", "CaseRelationKey", "relationship")]
                [InlineData("frmText", "T", "TextTypeKey", "textType")]
                public void ApplyAddWithSingleFilter(string name, string type, string filterName, string filterType)
                {
                    var filterValue = Fixture.String();

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta(name, type, filterType, filterValue)
                            {
                                ScreenTip = "ABC",
                                Title = "DEF",
                                IsMandatory = true
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    var updatedTopic = _entry.WorkflowWizard.TopicControls.First();
                    Assert.Equal("DEF", updatedTopic.Title);
                    Assert.Equal("ABC", updatedTopic.ScreenTip);
                    Assert.True(updatedTopic.IsMandatory);
                    Assert.Equal(1, updatedTopic.Filters.Count);
                    Assert.Equal(filterName, updatedTopic.Filters.Single().FilterName);
                    Assert.Equal(filterValue, updatedTopic.Filters.Single().FilterValue);
                }

                [Fact]
                public void ApplyAddWithBothFilters()
                {
                    var nameTypeKey = Fixture.String();
                    var textTypeKey = Fixture.String();

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmNameText", "X", "nameType", nameTypeKey, "textType", textTypeKey)
                            {
                                ScreenTip = "ABC",
                                Title = "DEF",
                                IsMandatory = true
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    var updatedTopic = _entry.WorkflowWizard.TopicControls.First();

                    Assert.Equal("DEF", updatedTopic.Title);
                    Assert.Equal("ABC", updatedTopic.ScreenTip);
                    Assert.True(updatedTopic.IsMandatory);
                    Assert.Equal(2, updatedTopic.Filters.Count);
                    Assert.Equal("NameTypeKey", updatedTopic.Filters.First().FilterName);
                    Assert.Equal(nameTypeKey, updatedTopic.Filters.First().FilterValue);
                    Assert.Equal("TextTypeKey", updatedTopic.Filters.Last().FilterName);
                    Assert.Equal(textTypeKey, updatedTopic.Filters.Last().FilterValue);
                }

                [Fact]
                public void ApplyAddWithNoFilters()
                {
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                            {
                                ScreenTip = "ABC",
                                Title = "DEF",
                                IsMandatory = true
                            }
                        }
                    };

                    var update = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, update);

                    var updatedTopic = _entry.WorkflowWizard.TopicControls.First();

                    Assert.Equal("DEF", updatedTopic.Title);
                    Assert.Equal("ABC", updatedTopic.ScreenTip);
                    Assert.True(updatedTopic.IsMandatory);
                    Assert.Empty(updatedTopic.Filters);
                }

                [Fact]
                public void InheritanceFlagIsSetIfResettingEntry()
                {
                    _model.CriteriaId = _entry.CriteriaId;
                    _model.Id = _entry.Id;
                    _model.ResetInheritance = true;
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                        }
                    };

                    var additions = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, additions);

                    Assert.True(_entry.WorkflowWizard.TopicControls.Single().IsInherited);
                }

                [Fact]
                public void InheritedFlagSetFalseInEntry()
                {
                    _model.CriteriaId = _entry.CriteriaId;
                    _model.Id = _entry.Id;
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                        }
                    };

                    var additions = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, additions);

                    var addedTopic = _entry.WorkflowWizard.TopicControls.Single();

                    Assert.False(addedTopic.IsInherited);
                }

                [Fact]
                public void InheritedFlagSetTrueInChild()
                {
                    _model.CriteriaId = _entry.CriteriaId;
                    _model.Id = _entry.Id;
                    var childEntry = new DataEntryTaskBuilder(new Criteria()).WithParentInheritance(_entry.Id).Build().In(Db);
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                        }
                    };

                    var additions = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(childEntry, _model, additions);

                    var addedTopic = childEntry.WorkflowWizard.TopicControls.Single();

                    Assert.True(addedTopic.IsInherited);
                }

                [Fact]
                public void InsertAtOverridePositionForReset()
                {
                    var topic1 = new TopicControl("frm1") {RowPosition = 0}.In(Db);
                    _entry.AddWorkflowWizardStep(topic1);

                    _model.ResetInheritance = true;
                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                            {
                                OverrideRowPosition = 9
                            }
                        },
                        Updated = new[]
                        {
                            new StepDelta("frm1", "G")
                            {
                                Id = topic1.Id,
                                OverrideRowPosition = 8
                            }
                        }
                    };

                    var additions = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;
                    subject.ApplyChanges(_entry, _model, additions);

                    var topics = _entry.WorkflowWizard.TopicControls;
                    var added = topics.Single(_ => _.Name == "frmGeneral");
                    var updated = topics.Single(_ => _.Name == "frm1");

                    Assert.Equal(9, added.RowPosition);
                    Assert.Equal(8, updated.RowPosition);
                }

                [Fact]
                public void InsertAtRelativePosition()
                {
                    var topic1 = new TopicControl("frm1") {RowPosition = 0}.In(Db);
                    var topic2 = new TopicControl("frm2") {RowPosition = 1}.In(Db);
                    _entry.AddWorkflowWizardStep(topic1, topic2);

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                            {
                                RelativeId = topic1.Id.ToString()
                            }
                        }
                    };

                    var additions = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, additions);

                    var addedTopic = _entry.WorkflowWizard.TopicControls.OrderBy(_ => _.RowPosition).ToArray();

                    Assert.Equal(topic1.Name, addedTopic[0].Name);
                    Assert.Equal("frmGeneral", addedTopic[1].Name);
                    Assert.Equal(topic2.Name, addedTopic[2].Name);
                }

                [Fact]
                public void InsertAtRelativePositionWithAddedStep()
                {
                    var topic1 = new TopicControl("frm1") {RowPosition = 0}.In(Db);
                    var topic2 = new TopicControl("frm2") {RowPosition = 1}.In(Db);
                    _entry.AddWorkflowWizardStep(topic1, topic2);

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmGeneral1", "G")
                            {
                                RelativeId = topic1.Id.ToString(),
                                NewItemId = "A"
                            },
                            new StepDelta("frmGeneral2", "G")
                            {
                                RelativeId = "A"
                            }
                        }
                    };

                    var additions = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, additions);

                    var addedTopic = _entry.WorkflowWizard.TopicControls.OrderBy(_ => _.RowPosition).ToArray();

                    Assert.Equal(topic1.Name, addedTopic[0].Name);
                    Assert.Equal("frmGeneral1", addedTopic[1].Name);
                    Assert.Equal("frmGeneral2", addedTopic[2].Name);
                    Assert.Equal(topic2.Name, addedTopic[3].Name);
                }

                [Fact]
                public void InsertAtRelativePositionWithUpdatedStep()
                {
                    var topic1 = new TopicControl("frm1") {RowPosition = 0}.In(Db);
                    var topic2 = new TopicControl("frm2") {RowPosition = 1}.In(Db);
                    _entry.AddWorkflowWizardStep(topic1, topic2);

                    _model.StepsDelta = new Delta<StepDelta>
                    {
                        Updated = new[]
                        {
                            new StepDelta("frm1", "G")
                            {
                                Categories = new[] {new StepCategory("checklist", "1")},
                                Id = topic1.Id
                            }
                        },
                        Added = new[]
                        {
                            new StepDelta("frmGeneral", "G")
                            {
                                RelativeId = topic1.Id.ToString()
                            }
                        }
                    };

                    var additions = new EntryControlFieldsToUpdate(_entry, _model);

                    var subject = new StepMaintenanceFixture(Db).Subject;

                    subject.ApplyChanges(_entry, _model, additions);

                    var addedTopic = _entry.WorkflowWizard.TopicControls.OrderBy(_ => _.RowPosition).ToArray();

                    Assert.Equal(topic1.Name, addedTopic[0].Name);
                    Assert.Equal("frmGeneral", addedTopic[1].Name);
                    Assert.Equal(topic2.Name, addedTopic[2].Name);
                }
            }
        }

        public class RemoveInheritanceMethod : FactBase
        {
            public RemoveInheritanceMethod()
            {
                _model.CriteriaId = _entry.CriteriaId;

                _entryStep = _entry.BuildStep(Db, "frmGeneral");
                _entryStep.IsInherited = true;

                _childInheritedStep = _child.BuildStep(Db, "frmGeneral");
                _childInheritedStep.IsInherited = true;
            }

            readonly DataEntryTask _child = new DataEntryTaskBuilder().Build();
            readonly TopicControl _childInheritedStep;
            readonly DataEntryTask _entry = new DataEntryTaskBuilder().Build();
            readonly TopicControl _entryStep;
            readonly WorkflowEntryControlSaveModel _model = new WorkflowEntryControlSaveModel();

            [Fact]
            public void BreaksInheritanceDuringDeleteForCorrespondingChildEntry()
            {
                _model.StepsDelta = new Delta<StepDelta>
                {
                    Deleted = new[]
                    {
                        new StepDelta("frmGeneral", "G")
                        {
                            Id = _entryStep.Id
                        }
                    }
                };

                new StepMaintenanceFixture(Db).Subject.RemoveInheritance(_child, new EntryControlFieldsToUpdate(_entry, _model));

                Assert.True(_entryStep.IsInherited);
                Assert.False(_childInheritedStep.IsInherited);
            }

            [Fact]
            public void BreaksInheritanceDuringUpdateForCorrespondingChildEntry()
            {
                _model.StepsDelta = new Delta<StepDelta>
                {
                    Updated = new[]
                    {
                        new StepDelta("frmGeneral", "G")
                        {
                            Id = _entryStep.Id
                        }
                    }
                };

                new StepMaintenanceFixture(Db).Subject.RemoveInheritance(_child, new EntryControlFieldsToUpdate(_entry, _model));

                Assert.False(_childInheritedStep.IsInherited);
            }
        }

        public class UpdateDisplayOrder : FactBase
        {
            Criteria BuildWithEntrySteps(params string[] steps)
            {
                var criteria = new Criteria().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria)
                                    .BuildWithSteps(Db, steps)
                                    .In(Db);
                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};
                return criteria;
            }

            Criteria BuildWithEntryStepsContainingFilters(params string[] steps)
            {
                var stepDistinctCount = steps.Distinct().ToDictionary(key => key, value => 1);
                var criteria = new Criteria().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria).Build();

                foreach (var s in steps)
                    entryToUpdate.WithStep(Db, s, new TopicControlFilter(s, stepDistinctCount[s]++.ToString()).In(Db));

                entryToUpdate.In(Db);

                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};
                return criteria;
            }

            [Fact]
            public void MovesDown()
            {
                var criteria = BuildWithEntrySteps("apple", "banana", "coconut", "durian", "emuberry");
                var entryToUpdate = criteria.DataEntryTasks.Single();
                var coconut = entryToUpdate.SingleStepByName("coconut");
                var durian = entryToUpdate.SingleStepByName("durian");
                var apple = entryToUpdate.SingleStepByName("apple");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    CriteriaId = criteria.Id,
                    StepsMoved = new[]
                    {
                        new StepMovements(coconut.Id, durian.Id.ToString()), /* move coconut to 2nd last */
                        new StepMovements(apple.Id, durian.Id.ToString()) /* move apple following durian */
                    }
                };

                new StepMaintenanceFixture(Db).Subject.UpdateDisplayOrder(entryToUpdate, new EntryControlRecordMovements(entryToUpdate, updatedValues));

                var expected = new[]
                {
                    "banana", "durian", "apple", "coconut", "emuberry"
                };

                var result = entryToUpdate.StepsInDisplayOrder().Names();

                Assert.Equal(expected, result);
            }

            [Fact]
            public void MovesEitherWays()
            {
                var criteria = BuildWithEntryStepsContainingFilters("apple", "apple", "coconut", "durian", "emuberry");
                var entryToUpdate = criteria.DataEntryTasks.Single();

                var apple1 = entryToUpdate.StepsByName("apple").First();
                var apple2 = entryToUpdate.StepsByName("apple").Skip(1).First();
                var coconut = entryToUpdate.SingleStepByName("coconut");
                var durian = entryToUpdate.SingleStepByName("durian");
                var emuberry = entryToUpdate.SingleStepByName("emuberry");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    CriteriaId = criteria.Id,
                    StepsMoved = new[]
                    {
                        new StepMovements(apple2.Id), /* "apple2", "apple1", "coconut", "durian", "emuberry" */
                        new StepMovements(emuberry.Id, apple2.Id.ToString()), /* "apple2", "emuberry", "apple1", "coconut", "durian" */
                        new StepMovements(apple1.Id, durian.Id.ToString()), /* "apple2", "emuberry", "coconut", "durian", "apple1" */
                        new StepMovements(coconut.Id) /* "coconut", "apple2", "emuberry", "durian", "apple1" */
                    }
                };

                new StepMaintenanceFixture(Db).Subject.UpdateDisplayOrder(entryToUpdate, new EntryControlRecordMovements(entryToUpdate, updatedValues));

                var expected = new[]
                {
                    "coconut", "apple", "emuberry", "durian", "apple"
                };

                var result = entryToUpdate.StepsInDisplayOrder().Names();

                Assert.Equal(expected, result);

                Assert.Equal(apple2, entryToUpdate.StepsInDisplayOrder().Skip(1).First());
                Assert.Equal(apple1, entryToUpdate.StepsInDisplayOrder().Last());
            }

            [Fact]
            public void MovesUp()
            {
                var criteria = BuildWithEntrySteps("apple", "banana", "coconut", "durian", "emuberry");
                var entryToUpdate = criteria.DataEntryTasks.Single();
                var banana = entryToUpdate.SingleStepByName("banana");
                var emuberry = entryToUpdate.SingleStepByName("emuberry");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    CriteriaId = criteria.Id,
                    StepsMoved = new[]
                    {
                        new StepMovements(banana.Id), /* move banana to top of the bunch */
                        new StepMovements(emuberry.Id, banana.Id.ToString()) /* move enumberry following banana */
                    }
                };

                new StepMaintenanceFixture(Db).Subject.UpdateDisplayOrder(entryToUpdate, new EntryControlRecordMovements(entryToUpdate, updatedValues));

                var expected = new[]
                {
                    "banana", "emuberry", "apple", "coconut", "durian"
                };

                var result = entryToUpdate.StepsInDisplayOrder().Names();

                Assert.Equal(expected, result);
            }

            [Fact]
            public void SetsNextStepHash()
            {
                var criteria = BuildWithEntryStepsContainingFilters("apple", "apple", "coconut", "durian", "emuberry");
                var entryToUpdate = criteria.DataEntryTasks.Single();

                var apple1 = entryToUpdate.StepsByName("apple").First();
                var apple2 = entryToUpdate.StepsByName("apple").Skip(1).First();
                var coconut = entryToUpdate.SingleStepByName("coconut");
                var durian = entryToUpdate.SingleStepByName("durian");
                var emuberry = entryToUpdate.SingleStepByName("emuberry");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    CriteriaId = criteria.Id,
                    StepsMoved = new[]
                    {
                        new StepMovements(apple2.Id), /* "apple2", "apple1", "coconut", "durian", "emuberry" */
                        new StepMovements(emuberry.Id, apple2.Id.ToString()), /* "apple2", "emuberry", "apple1", "coconut", "durian" */
                        new StepMovements(apple1.Id, durian.Id.ToString()), /* "apple2", "emuberry", "coconut", "durian", "apple1" */
                        new StepMovements(coconut.Id, apple2.Id.ToString()) /* "apple2", "coconut", "emuberry", "durian", "apple1" */
                    }
                };

                var movements = new EntryControlRecordMovements(entryToUpdate, updatedValues);
                new StepMaintenanceFixture(Db).Subject.UpdateDisplayOrder(entryToUpdate, movements);

                /* Based on - "apple2", "coconut", "emuberry", "durian", "apple1" */
                Assert.Null(movements.StepMovements[0].NextStepHashCode);
                Assert.Equal(durian.HashCode(), movements.StepMovements[1].NextStepHashCode);

                Assert.Null(movements.StepMovements[2].NextStepHashCode);
                Assert.Equal(emuberry.HashCode(), movements.StepMovements[3].NextStepHashCode);
            }
        }

        public class PropagateDisplayOrderMethod : FactBase
        {
            public PropagateDisplayOrderMethod()
            {
                _fixture = new StepMaintenanceFixture(Db);
            }

            readonly StepMaintenanceFixture _fixture;

            Criteria BuildWithEntryStepsContainingFilters(params string[] steps)
            {
                var stepDistinctCount = steps.Distinct().ToDictionary(key => key, value => 1);
                var criteria = new Criteria().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria).Build();

                foreach (var s in steps)
                    entryToUpdate.WithStep(Db, s, new TopicControlFilter(s, stepDistinctCount[s]++.ToString()).In(Db));

                entryToUpdate.In(Db);

                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};
                return criteria;
            }

            [Theory]
            [InlineData("apple,banana,coconut,durian,emuberry", "apple,banana,coconut,durian,emuberry", "banana,emuberry,coconut,durian,apple")]
            [InlineData("apple,banana,coconut,durian,emuberry", "apple,random,banana,coconut,durian,emuberry", "banana,emuberry,random,coconut,durian,apple")]
            [InlineData("apple,banana,coconut,durian,emuberry", "apple,coconut,random,durian,emuberry", "emuberry,coconut,random,durian,apple")]
            [InlineData("apple,banana,coconut,durian,emuberry", "yuzu,apple,watermelon,banana,coconut,tomato,durian,strawberry,emuberry,rambutan", "banana,emuberry,yuzu,watermelon,coconut,tomato,durian,apple,strawberry,rambutan")]
            [InlineData("apple,banana,coconut,durian,emuberry", "random,banana,coconut,durian", "banana,random,coconut,durian")]
            public void PropagatesWhenAllStepsAreInSameOrder(string strSource, string strTarget, string expected)
            {
                var source = BuildWithEntryStepsContainingFilters(strSource.Split(','));
                var target = BuildWithEntryStepsContainingFilters(strTarget.Split(','));

                var entryToUpdate = source.DataEntryTasks.Single();

                var banana = entryToUpdate.SingleStepByName("banana");
                var emuberry = entryToUpdate.SingleStepByName("emuberry");
                var coconut = entryToUpdate.SingleStepByName("coconut");
                var durian = entryToUpdate.SingleStepByName("durian");
                var apple = entryToUpdate.SingleStepByName("apple");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    CriteriaId = source.Id,
                    StepsMoved = new[]
                    {
                        new StepMovements(banana.Id),
                        new StepMovements(emuberry.Id, banana.Id.ToString()),
                        new StepMovements(apple.Id, durian.Id.ToString())
                    }
                };
                var movements = new EntryControlRecordMovements(entryToUpdate, updatedValues);

                var reorderSource = _fixture.Mapper.Map<EntryReorderSouce>(source.DataEntryTasks.Single());

                _fixture.Subject.UpdateDisplayOrder(entryToUpdate, movements);
                var result = _fixture.Subject.PropagateDisplayOrder(reorderSource, target.DataEntryTasks.Single(), movements);
                Db.SaveChanges();
                Assert.True(result);
                Assert.Equal(expected.Split(','), target.DataEntryTasks.Single().StepsInDisplayOrder().Names());
            }

            [Fact]
            public void ShouldNotPropagateIfAllCommonalityAreNotInSameOrder()
            {
                var source = BuildWithEntryStepsContainingFilters("apple", "apple", "coconut", "durian", "emuberry");
                var sourceEntry = source.DataEntryTasks.Single();
                var apple2 = sourceEntry.StepsByName("apple").Last();

                var target = BuildWithEntryStepsContainingFilters("apple", "coconut", "banana", "apple", "emuberry");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = source.DataEntryTasks.Single().Id,
                    CriteriaId = source.Id,
                    StepsMoved = new[]
                    {
                        new StepMovements(apple2.Id) /* "banana", "apple", "coconut", "durian", "emuberry" */
                    }
                };
                var movements = new EntryControlRecordMovements(sourceEntry, updatedValues);

                var reorderSource = _fixture.Mapper.Map<EntryReorderSouce>(source.DataEntryTasks.Single());

                var result = _fixture.Subject.PropagateDisplayOrder(reorderSource, target.DataEntryTasks.Single(), movements);

                Assert.False(result);
            }

            [Fact]
            public void ShouldNotPropagateIfTargetContainsNoSteps()
            {
                var source = BuildWithEntryStepsContainingFilters("apple", "banana", "coconut", "durian", "emuberry");
                var sourceEntry = source.DataEntryTasks.Single();
                var banana = sourceEntry.SingleStepByName("banana");

                var target = BuildWithEntryStepsContainingFilters();

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = sourceEntry.Id,
                    CriteriaId = source.Id,
                    StepsMoved = new[]
                    {
                        new StepMovements(banana.Id) /* "banana", "apple", "coconut", "durian", "emuberry" */
                    }
                };
                var movements = new EntryControlRecordMovements(sourceEntry, updatedValues);

                var reorderSource = _fixture.Mapper.Map<EntryReorderSouce>(source.DataEntryTasks.Single());

                var result = _fixture.Subject.PropagateDisplayOrder(reorderSource, target.DataEntryTasks.Single(), movements);

                Assert.False(result);
            }

            [Fact]
            public void ShouldPropagateOnlyIfMovementExists()
            {
                var source = BuildWithEntryStepsContainingFilters("apple", "banana", "coconut", "durian", "emuberry");

                var target = BuildWithEntryStepsContainingFilters("apple", "banana", "coconut", "durian", "emuberry");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = source.DataEntryTasks.Single().Id,
                    CriteriaId = source.Id,
                    StepsMoved = new StepMovements[0]
                };
                var movements = new EntryControlRecordMovements(source.DataEntryTasks.Single(), updatedValues);

                var reorderSource = _fixture.Mapper.Map<EntryReorderSouce>(source.DataEntryTasks.Single());

                var result = _fixture.Subject.PropagateDisplayOrder(reorderSource, target.DataEntryTasks.Single(), movements);

                Assert.False(result);
            }
        }

        public class Reset : FactBase
        {
            bool Compare(TopicControl t, StepDelta d)
            {
                var fieldsEqual = (t.Name + t.Title + t.ScreenTip + t.IsMandatory + t.RowPosition).GetHashCode() ==
                                  (d.Name + d.Title + d.ScreenTip + d.IsMandatory + d.OverrideRowPosition).GetHashCode();

                var filtersEqual = t.Filter1Value == d.Filter1Value && t.Filter2Value == d.Filter2Value;

                return fieldsEqual && filtersEqual;
            }

            [Fact]
            public void AddsStepsFromParent()
            {
                var f = new StepMaintenanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithSteps(Db, 2).In(Db);
                criteria.DataEntryTasks.Add(parentEntry);
                var step1 = parentEntry.TaskSteps.First().TopicControls.ElementAt(0);
                var step2 = parentEntry.TaskSteps.First().TopicControls.ElementAt(1);

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.BuildWithSteps(Db).In(Db);
                criteriaChild1.DataEntryTasks.Add(childEntry);

                var screen1 = new Screen {ScreenName = step1.Name, ScreenType = Fixture.String()}.In(Db);
                var screen2 = new Screen {ScreenName = step2.Name, ScreenType = Fixture.String()}.In(Db);

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(childEntry, parentEntry, saveModel);

                // Reset should add 2 Steps in the parent that weren't in the child (matching by hash)
                Assert.Equal(2, saveModel.StepsDelta.Added.Count);
                Assert.Empty(saveModel.StepsDelta.Updated);
                Assert.Empty(saveModel.StepsDelta.Deleted);

                var s1 = saveModel.StepsDelta.Added.Single(s => s.Name == step1.Name);
                Assert.True(Compare(step1, s1));
                Assert.Equal(screen1.ScreenType, s1.ScreenType);
                Assert.Equal(step1.RowPosition, s1.OverrideRowPosition);

                var s2 = saveModel.StepsDelta.Added.Single(s => s.Name == step2.Name);
                Assert.True(Compare(step2, s2));
                Assert.Equal(screen2.ScreenType, s2.ScreenType);
                Assert.Equal(step2.RowPosition, s2.OverrideRowPosition);
            }

            [Fact]
            public void DeletesStepsNotInParent()
            {
                var f = new StepMaintenanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithSteps(Db, 0).In(Db);
                criteria.DataEntryTasks.Add(parentEntry);

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.BuildWithSteps(Db, 2).In(Db);
                criteriaChild1.DataEntryTasks.Add(childEntry);
                var cStepId1 = childEntry.TaskSteps.First().TopicControls.ElementAt(0).Id;
                var cStepId2 = childEntry.TaskSteps.First().TopicControls.ElementAt(1).Id;

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(childEntry, parentEntry, saveModel);

                // Reset should delete 2 Steps in child not matching in the parent (by hash)
                Assert.Equal(2, saveModel.StepsDelta.Deleted.Count);
                Assert.Empty(saveModel.StepsDelta.Added);
                Assert.Empty(saveModel.StepsDelta.Updated);

                Assert.NotNull(saveModel.StepsDelta.Deleted.SingleOrDefault(s => s.Id == cStepId1));
                Assert.NotNull(saveModel.StepsDelta.Deleted.SingleOrDefault(s => s.Id == cStepId2));
            }

            [Fact]
            public void UpdatesMatchingStepsFromParent()
            {
                var f = new StepMaintenanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithSteps(Db, 1).In(Db);
                criteria.DataEntryTasks.Add(parentEntry);
                var pStep = parentEntry.TaskSteps.First().TopicControls.ElementAt(0);

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.BuildWithSteps(Db, 1).In(Db);
                criteriaChild1.DataEntryTasks.Add(childEntry);
                var cStep = childEntry.TaskSteps.First().TopicControls.ElementAt(0);
                // match the hashes
                cStep.Name = pStep.Name;
                cStep.Filter1Name = pStep.Filter1Name;
                cStep.Filter1Value = pStep.Filter1Value;
                cStep.Filter2Name = pStep.Filter2Name;
                cStep.Filter2Value = pStep.Filter2Value;

                var screen1 = new Screen {ScreenName = pStep.Name, ScreenType = Fixture.String()}.In(Db);

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(childEntry, parentEntry, saveModel);

                // Reset should update 1 Step that matches the hash in the child
                Assert.Equal(1, saveModel.StepsDelta.Updated.Count);
                Assert.Empty(saveModel.StepsDelta.Added);
                Assert.Empty(saveModel.StepsDelta.Deleted);

                var s1 = saveModel.StepsDelta.Updated.Single(s => s.Name == pStep.Name);
                Assert.True(Compare(pStep, s1));
                Assert.Equal(s1.Id, cStep.Id);
                Assert.Equal(screen1.ScreenType, s1.ScreenType);
                Assert.Equal(pStep.RowPosition, s1.OverrideRowPosition);
            }
        }

        public class StepMaintenanceFixture : IFixture<StepsMaintenance>
        {
            public StepMaintenanceFixture(InMemoryDbContext db)
            {
                var m = new Mapper(new MapperConfiguration(cfg =>
                {
                    cfg.AddProfile(new EntryControlMaintenanceProfile());
                    cfg.CreateMissingTypeMaps = true;
                }));

                Mapper = m.DefaultContext.Mapper.DefaultContext.Mapper;

                WorkflowEntryStepsService = Substitute.For<IWorkflowEntryStepsService>();
                ChangeTracker = Substitute.For<IChangeTracker>();

                ChangeTracker.HasChanged(null).ReturnsForAnyArgs(true);

                Subject = new StepsMaintenance(WorkflowEntryStepsService, db, Mapper, ChangeTracker);
            }

            public IWorkflowEntryStepsService WorkflowEntryStepsService { get; set; }

            public IMapper Mapper { get; }

            public IChangeTracker ChangeTracker { get; }

            public StepsMaintenance Subject { get; }
        }
    }

    public static class TopicControlExt
    {
        public static string[] Names(this IOrderedEnumerable<TopicControl> steps)
        {
            return steps.Select(_ => _.Name).ToArray();
        }
    }
}