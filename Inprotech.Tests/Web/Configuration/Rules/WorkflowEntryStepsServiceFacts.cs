using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration.Screens;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using AvailableTopicModel = InprotechKaizen.Model.Components.Configuration.AvailableTopic;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEntryStepsServiceFacts
    {
        public class GetStepsMethod : FactBase
        {
            public GetStepsMethod()
            {
                _entry.In(Db);
                _entry.Criteria.In(Db);
            }

            readonly DataEntryTask _entry = new DataEntryTaskBuilder
            {
                Criteria = new CriteriaBuilder().ForEventsEntriesRule().Build(),
                EntryNumber = 1
            }.Build();

            [Theory]
            [InlineData("ChecklistTypeKey", "checklist")]
            [InlineData("CountryFlag", "designationStage")]
            [InlineData("NameGroupKey", "nameTypeGroup")]
            [InlineData("NameTypeKey", "nameType")]
            [InlineData("TextTypeKey", "textType")]
            [InlineData("CreateActionKey", "action")]
            [InlineData("CaseRelationKey", "relationship")]
            [InlineData("NumberTypeKeys", "numberType")]
            public void PopulateSingularFilterSteps(string topicControlFilterKey, string stepFilterProviderCode)
            {
                var topicName = Fixture.String();

                var workflowWizard = WindowControlBuilder.For(_entry).Build().In(Db);

                var topic = TopicControlBuilder.For(workflowWizard, topicName).Build().In(Db);

                var value = Fixture.String();

                topic.Filters.Add(new TopicControlFilter(topicControlFilterKey, value).In(Db));

                _entry.TaskSteps.Add(workflowWizard);

                var fixture = new WorkflowEntryStepsServiceFixture(Db).WithTopics(new AvailableTopicModel(topicName));

                var result = fixture.Subject.GetSteps(_entry.Criteria.Id, _entry.Id).Single();

                Assert.Single(result.Categories);

                Assert.Equal(stepFilterProviderCode, result.Categories.First().CategoryCode);

                Assert.Equal(value, result.Categories.First().CategoryValue);
            }

            [Fact]
            public void PopulateMultipleFilterSteps()
            {
                var topicName = Fixture.String();

                var workflowWizard = WindowControlBuilder.For(_entry).Build().In(Db);

                var topic = TopicControlBuilder.For(workflowWizard, topicName).Build().In(Db);

                var value1 = Fixture.String();

                var value2 = Fixture.String();

                topic.Filters.Add(new TopicControlFilter("NameTypeKey", value1).In(Db));

                topic.Filters.Add(new TopicControlFilter("TextTypeKey", value2).In(Db));

                _entry.TaskSteps.Add(workflowWizard);

                var fixture = new WorkflowEntryStepsServiceFixture(Db).WithTopics(new AvailableTopicModel(topicName));

                var result = fixture.Subject.GetSteps(_entry.Criteria.Id, _entry.Id).Single();

                Assert.Equal("nameType", result.Categories.ElementAt(0).CategoryCode);

                Assert.Equal(value1, result.Categories.ElementAt(0).CategoryValue);

                Assert.Equal("textType", result.Categories.ElementAt(1).CategoryCode);

                Assert.Equal(value2, result.Categories.ElementAt(1).CategoryValue);
            }

            [Fact]
            public void ReturnsStepsFromWindowControl()
            {
                var workflowWizard = WindowControlBuilder.For(_entry).Build().In(Db);

                TopicControlBuilder.For(workflowWizard, "frmGeneral").Build().In(Db);

                TopicControlBuilder.For(workflowWizard, "frmRenewals").Build().In(Db);

                _entry.TaskSteps.Add(workflowWizard);

                var fixture = new WorkflowEntryStepsServiceFixture(Db)
                    .WithTopics(new AvailableTopicModel("frmGeneral"), new AvailableTopicModel("frmRenewals"));

                var result = fixture.Subject.GetSteps(_entry.Criteria.Id, _entry.Id);

                Assert.Equal(2, result.Count());
            }

            [Fact]
            public void ShouldNotPopulateFilterIfUnknown()
            {
                var topicName = Fixture.String();

                var workflowWizard = WindowControlBuilder.For(_entry).Build().In(Db);

                var topic = TopicControlBuilder.For(workflowWizard, topicName).Build().In(Db);

                topic.Filters.Add(new TopicControlFilter("random", Fixture.String()).In(Db));

                _entry.TaskSteps.Add(workflowWizard);

                var fixture = new WorkflowEntryStepsServiceFixture(Db).WithTopics(new AvailableTopicModel(topicName));

                var result = fixture.Subject.GetSteps(_entry.Criteria.Id, _entry.Id).ToArray();

                Assert.Empty(result.First().Categories);
            }

            [Fact]
            public void ShouldNotReturnAnyIfNotConfigured()
            {
                var fixture = new WorkflowEntryStepsServiceFixture(Db);
                var result = fixture.Subject.GetSteps(_entry.Criteria.Id, _entry.Id);

                Assert.Empty(result);
            }
        }

        public class ValidateMethod : FactBase
        {
            [Theory]
            [InlineData("frmOfficialNo", "O", "numberType")]
            [InlineData("frmRelationships", "M", "relationship")]
            public void ReturnDuplicateIfThereAreMultipleAppearOnceTopics(string stepToAdd, string stepType, string category)
            {
                var newAddedId = -10;
                var entry = new DataEntryTaskBuilder().Build().In(Db);

                entry.WithStep(Db, "frmOfficialNo", new TopicControlFilter("NumberTypeKey", "&"))
                     .WithStep(Db, "frmRelationships", new TopicControlFilter("CaseRelationshipKey", "BAS"));

                var saveModel = new WorkflowEntryControlSaveModel
                {
                    StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta(stepToAdd, stepType, category, Fixture.String()) {Id = newAddedId}
                        }
                    }
                };

                var fixture = new WorkflowEntryStepsServiceFixture(Db);

                var result = fixture.Subject.Validate(entry, saveModel);

                var duplicates = result.Single().Id;

                Assert.Equal(newAddedId, duplicates);
            }

            [Theory]
            [InlineData("Add")]
            [InlineData("Update")]
            public void ShouldNotReturnRequiredForOptionaFilterSteps(string mode)
            {
                var entry = new DataEntryTaskBuilder().Build().In(Db);
                var saveModel = new WorkflowEntryControlSaveModel
                {
                    StepsDelta = new Delta<StepDelta>
                    {
                        Added = mode == "Add"
                            ? new[]
                            {
                                new StepDelta("frmOfficialNo", "O", "numberType", null),
                                new StepDelta("frmRelationships", "M", "relationship", null)
                            }
                            : new StepDelta[0],
                        Updated = mode == "Update"
                            ? new[]
                            {
                                new StepDelta("frmOfficialNo", "O", "numberType", null),
                                new StepDelta("frmRelationships", "M", "relationship", null)
                            }
                            : new StepDelta[0]
                    }
                };

                var fixture = new WorkflowEntryStepsServiceFixture(Db);

                Assert.Empty(fixture.Subject.Validate(entry, saveModel));
            }

            [Theory]
            [InlineData("frmChecklist", "C", "checklist")]
            [InlineData("frmNameGroup", "P", "nameGroup")]
            [InlineData("frmAction", "A", "action")]
            [InlineData("frmNameType", "N", "nameType")]
            [InlineData("frmTextType", "T", "textType")]
            public void ShouldReturnRequiredForOtherFilterEnabledSteps(string name, string type, string category)
            {
                const string newAddedId = "A";
                var entry = new DataEntryTaskBuilder().Build().In(Db);
                var saveModel = new WorkflowEntryControlSaveModel
                {
                    StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta(name, type, category, null) {NewItemId = newAddedId}
                        }
                    }
                };

                var fixture = new WorkflowEntryStepsServiceFixture(Db);

                var result = fixture.Subject.Validate(entry, saveModel);

                var required = result.Select(_ => _.Id).Cast<string>().Single();

                Assert.Equal(newAddedId, required);
            }

            [Fact]
            public void ReturnsDuplicate()
            {
                var newAddedIds = new[] {-11, -12, -13};
                var entry = new DataEntryTaskBuilder().Build().In(Db);

                entry.WithStep(Db, "frmGeneral")
                     .WithStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "1"))
                     .WithStep(Db, "frmActions", new TopicControlFilter("CreateActionKey", "AL"))
                     .WithStep(Db, "frmNameText", new TopicControlFilter("NameTypeKey", "&"), new TopicControlFilter("TextTypeKey", "_C"));

                var saveModel = new WorkflowEntryControlSaveModel
                {
                    StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmGeneral", "G") {Id = newAddedIds[0]},
                            new StepDelta("frmChecklist", "C", "checklist", "1") {Id = newAddedIds[1]},
                            new StepDelta("frmNameText", "C", "nameType", "&", "textType", "_C") {Id = newAddedIds[2]}
                        },
                        Updated = new[]
                        {
                            new StepDelta("frmActions", "A", "action", "AL")
                            {
                                ScreenTip = "added this screen tip"
                            }
                        }
                    }
                };

                var fixture = new WorkflowEntryStepsServiceFixture(Db);

                var result = fixture.Subject.Validate(entry, saveModel);

                var duplicates = result.Select(_ => _.Id).Cast<int>().OrderByDescending(id => id).ToArray();

                Assert.Equal(newAddedIds, duplicates);
            }

            [Fact]
            public void ReturnsDuplicateIfSameItemWereAddedAndUpdated()
            {
                var newAddedId = -10;
                var entry = new DataEntryTaskBuilder().Build().In(Db);

                entry.WithStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "1"));
                var existingStepId = entry.TaskSteps.Single().Id;

                var saveModel = new WorkflowEntryControlSaveModel
                {
                    StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmChecklist", "C", "checklist", "1")
                            {
                                Id = newAddedId
                            }
                        },
                        Updated = new[]
                        {
                            new StepDelta("frmChecklist", "C", "checklist", "1")
                            {
                                ScreenTip = "added this screen tip",
                                Id = existingStepId
                            }
                        }
                    }
                };

                var fixture = new WorkflowEntryStepsServiceFixture(Db);

                var result = fixture.Subject.Validate(entry, saveModel);

                var duplicates = result.Select(_ => _.Id).Cast<int>().ToArray();

                Assert.Equal(new[] {newAddedId, existingStepId}, duplicates);
            }

            [Fact]
            public void ShouldNotFlagDuplicate()
            {
                var entry = new DataEntryTaskBuilder().Build().In(Db);

                entry.WithStep(Db, "frmGeneral")
                     .WithStep(Db, "frmChecklist", new TopicControlFilter("ChecklistTypeKey", "1"))
                     .WithStep(Db, "frmActions", new TopicControlFilter("CreateActionKey", "AL"))
                     .WithStep(Db, "frmNameText", new TopicControlFilter("NameTypeKey", "&"), new TopicControlFilter("TextTypeKey", "_C"));

                var saveModel = new WorkflowEntryControlSaveModel
                {
                    StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmAbc", "G"),
                            new StepDelta("frmChecklist", "C", "checklist", "2"),
                            new StepDelta("frmNameText", "C", "nameType", "&", "textType", "_C1")
                        },
                        Updated = new[]
                        {
                            new StepDelta("frmActions", "A", "action", "R")
                        }
                    }
                };

                var fixture = new WorkflowEntryStepsServiceFixture(Db);

                Assert.Empty(fixture.Subject.Validate(entry, saveModel));
            }

            [Fact]
            public void ShouldReturnRequiredForMultiFilterSteps()
            {
                const string category1Filter = "nameType";
                const string category2Filter = "textType";

                const string newAddedId = "A";
                const int updatedId = -10;
                var entry = new DataEntryTaskBuilder().Build().In(Db);
                var saveModel = new WorkflowEntryControlSaveModel
                {
                    StepsDelta = new Delta<StepDelta>
                    {
                        Added = new[]
                        {
                            new StepDelta("frmNameText", "X", category1Filter, "some value", category2Filter, null) {NewItemId = newAddedId}
                        },
                        Updated = new[]
                        {
                            new StepDelta("frmNames", "N", category1Filter, null) {Id = updatedId}
                        }
                    }
                };

                var fixture = new WorkflowEntryStepsServiceFixture(Db);

                var result = fixture.Subject.Validate(entry, saveModel).ToArray();

                var required = result.Select(_ => _.Id).OfType<string>().ToArray();

                Assert.Contains(newAddedId, required);
                Assert.Contains(updatedId.ToString(), required);
            }
        }

        public class WorkflowEntryStepsServiceFixture : IFixture<WorkflowEntryStepsService>
        {
            public WorkflowEntryStepsServiceFixture(InMemoryDbContext db)
            {
                AvailableTopicsReader = Substitute.For<IAvailableTopicsReader>();

                Categories = new[]
                {
                    "checklist", "designationStage", "nameTypeGroup", "nameType", "textType", "action", "relationship", "numberType"
                }.ToDictionary(k => k, v => (IStepCategory) null);

                foreach (var key in Categories.Keys.ToArray())
                {
                    Categories[key] = Substitute.For<IStepCategory>();
                    Categories[key].CategoryType.Returns(key);
                    Categories[key].Get(Arg.Any<TopicControlFilter>(), Arg.Any<Criteria>())
                                   .Returns(x =>
                                   {
                                       var filter = (TopicControlFilter) x[0];
                                       var categoryType = StepCategoryCodes.PickerName(filter.FilterName);
                                       return new StepCategory(categoryType, filter.FilterValue);
                                   });
                }

                PermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
                PermissionHelper.CanEdit(Arg.Any<Criteria>()).Returns(true);

                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new WorkflowEntryStepsService(db, PermissionHelper, AvailableTopicsReader, Categories.Values, PreferredCultureResolver);
            }

            public IAvailableTopicsReader AvailableTopicsReader { get; set; }

            public Dictionary<string, IStepCategory> Categories { get; set; }

            public IWorkflowPermissionHelper PermissionHelper { get; set; }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public WorkflowEntryStepsService Subject { get; }

            public WorkflowEntryStepsServiceFixture WithTopics(params AvailableTopicModel[] availableTopicModel)
            {
                AvailableTopicsReader.Retrieve().Returns(availableTopicModel.AsQueryable());
                return this;
            }
        }
    }
}