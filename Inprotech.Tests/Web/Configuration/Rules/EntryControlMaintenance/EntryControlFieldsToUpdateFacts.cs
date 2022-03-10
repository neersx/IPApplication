using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration.Screens;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;
using Xunit;
using EntryMaintenance = Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance
{
    public class EntryControlFieldsToUpdateFacts
    {
        public class StepDelta : FactBase
        {
            public StepDelta()
            {
                _entryToUpdate = new DataEntryTaskBuilder(new Criteria(), 1) {Description = "A new Entry"}.Build().In(Db);
                _entryToUpdate.AddWorkflowWizardStep();
                _topic1 = new TopicControlBuilder
                {
                    Name = "topic1",
                    TopicControlFilters = new List<TopicControlFilter> {new TopicControlFilter("filter1", "filter1Value")},
                    WindowControl = _entryToUpdate.WorkflowWizard
                }.Build().In(Db);

                _topic2 = new TopicControlBuilder
                {
                    Name = "topic2",
                    TopicControlFilters = new List<TopicControlFilter> {new TopicControlFilter("filter1", "filter1Value")},
                    WindowControl = _entryToUpdate.WorkflowWizard
                }.Build().In(Db);
            }

            readonly DataEntryTask _entryToUpdate;
            readonly TopicControl _topic1;
            readonly TopicControl _topic2;

            [Fact]
            public void AdditionsSetCorrectly()
            {
                var saveModel = new WorkflowEntryControlSaveModel
                {
                    CriteriaId = _entryToUpdate.CriteriaId,
                    Id = _entryToUpdate.Id
                };
                //Updated Topic
                var topic2Updated = new Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps.StepDelta("topic2", string.Empty)
                {
                    Id = _topic2.Id,
                    Categories = new[] {new StepCategory("filter2", "value is updated")}
                };

                //Added - Without relative id
                var topicAdded1 = new Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps.StepDelta("topicNew1", string.Empty) {NewItemId = "A"};

                //Added - Relative to added above
                var topicAddedRelativeIdOfNewTopic1 = new Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps.StepDelta("topicNew2", string.Empty) {RelativeId = "A"};

                //Added - Relative to existing topic
                var topicWithRelativeIdOfTopic1 = new Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps.StepDelta("topicNew3", string.Empty)
                {
                    Categories = new[] {new StepCategory("CategoryNew1", "CategoryNewValue1")},
                    RelativeId = _topic1.Id.ToString()
                };

                //Added - Relative to updated topic
                var topicWithRelativeIdOfTopic2 = new Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps.StepDelta("topicNew4", string.Empty) {RelativeId = _topic2.Id.ToString()};

                saveModel.StepsDelta.Updated.Add(topic2Updated);

                saveModel.StepsDelta.Added.Add(topicAdded1);
                saveModel.StepsDelta.Added.Add(topicAddedRelativeIdOfNewTopic1);
                saveModel.StepsDelta.Added.Add(topicWithRelativeIdOfTopic1);
                saveModel.StepsDelta.Added.Add(topicWithRelativeIdOfTopic2);

                var fieldUpdates = new EntryMaintenance.EntryControlFieldsToUpdate(_entryToUpdate, saveModel);

                Assert.Equal(4, fieldUpdates.StepsDelta.Added.Count);

                //Added - Without relative id
                var addedTopic1 = fieldUpdates.StepsDelta.Added.ToArray()[0];
                Assert.Null(addedTopic1.OriginalHashCode);
                Assert.Equal(topicAdded1.HashCode(), addedTopic1.NewHashCode);
                Assert.Null(addedTopic1.RelativeHashCode);

                //Added - Relative to added above
                var addedTopic2 = fieldUpdates.StepsDelta.Added.ToArray()[1];
                Assert.Null(addedTopic2.OriginalHashCode);
                Assert.Equal(topicAddedRelativeIdOfNewTopic1.HashCode(), addedTopic2.NewHashCode);
                Assert.Equal(topicAdded1.HashCode(), addedTopic2.RelativeHashCode);

                //Added - Relative to existing topic
                var addedTopic3 = fieldUpdates.StepsDelta.Added.ToArray()[2];
                Assert.Null(addedTopic3.OriginalHashCode);
                Assert.Equal(topicWithRelativeIdOfTopic1.HashCode(), addedTopic3.NewHashCode);
                Assert.Equal(_topic1.HashCode(), addedTopic3.RelativeHashCode);

                //Added - Relative to updated topic
                var addedTopic4 = fieldUpdates.StepsDelta.Added.ToArray()[3];
                Assert.Null(addedTopic4.OriginalHashCode);
                Assert.Equal(topicWithRelativeIdOfTopic2.HashCode(), addedTopic4.NewHashCode);
                Assert.Equal(topic2Updated.HashCode(), addedTopic4.RelativeHashCode);
            }

            [Fact]
            public void DeletionsSetCorrectly()
            {
                var saveModel = new WorkflowEntryControlSaveModel
                {
                    CriteriaId = _entryToUpdate.CriteriaId,
                    Id = _entryToUpdate.Id
                };

                var topicToDelete = new Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps.StepDelta("topic2", string.Empty)
                {
                    Id = _topic2.Id,
                    Categories = new[] {new StepCategory("filter2", "value is updated")}
                };
                saveModel.StepsDelta.Deleted.Add(topicToDelete);

                var fieldUpdates = new EntryMaintenance.EntryControlFieldsToUpdate(_entryToUpdate, saveModel);

                Assert.Equal(1, fieldUpdates.StepsDelta.Deleted.Count);

                var deletedTopic = fieldUpdates.StepsDelta.Deleted.First();
                Assert.Equal(_topic2.HashCode(), deletedTopic.OriginalHashCode);
                Assert.Null(deletedTopic.NewHashCode);
                Assert.Null(deletedTopic.RelativeHashCode);
            }

            [Fact]
            public void UpdationsSetCorrectly()
            {
                var saveModel = new WorkflowEntryControlSaveModel
                {
                    CriteriaId = _entryToUpdate.CriteriaId,
                    Id = _entryToUpdate.Id
                };

                var topic2Updated = new Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps.StepDelta("topic2", string.Empty)
                {
                    Id = _topic2.Id,
                    Categories = new[] {new StepCategory("filter2", "value is updated")}
                };
                saveModel.StepsDelta.Updated.Add(topic2Updated);

                var fieldUpdates = new EntryMaintenance.EntryControlFieldsToUpdate(_entryToUpdate, saveModel);

                Assert.Equal(1, fieldUpdates.StepsDelta.Updated.Count);

                var updatedTopic = fieldUpdates.StepsDelta.Updated.First();
                Assert.Equal(_topic2.HashCode(), updatedTopic.OriginalHashCode);
                Assert.Equal(topic2Updated.HashCode(), updatedTopic.NewHashCode);
                Assert.Null(updatedTopic.RelativeHashCode);
            }
        }

        public class DataForSeprataorEntries : FactBase
        {
            public DataForSeprataorEntries()
            {
                _entryToUpdate = new DataEntryTaskBuilder(new Criteria(), 1) {Description = "A new Entry"}.AsSeparator().Build().In(Db);
            }

            readonly DataEntryTask _entryToUpdate;

            [Fact]
            public void OnlyDescriptionShouldBeConsideredForFieldsToUpdate()
            {
                var saveModel = new WorkflowEntryControlSaveModel
                {
                    CriteriaId = _entryToUpdate.CriteriaId,
                    Id = _entryToUpdate.Id,
                    UserInstruction = "abcd",
                    ShouldPoliceImmediate = true,
                    DimEventNo = -90
                };
                saveModel.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = 100, AlsoUpdateEventId = 90, DueAttribute = 1});
                saveModel.StepsDelta.Updated.Add(new Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps.StepDelta {Name = "abcd", Id = 1, ScreenType = "screen1"});
                saveModel.DocumentsDelta.Deleted.Add(new EntryDocumentDelta {DocumentId = 1});

                var fieldUpdates = new EntryMaintenance.EntryControlFieldsToUpdate(_entryToUpdate, saveModel);

                Assert.True(fieldUpdates.Description);
                Assert.False(fieldUpdates.UserInstruction);
                Assert.False(fieldUpdates.ShouldPoliceImmediate);
                Assert.False(fieldUpdates.DimEventNo);

                Assert.Empty(fieldUpdates.EntryEventsDelta.Added);
                Assert.Empty(fieldUpdates.StepsDelta.Updated);
                Assert.Empty(fieldUpdates.DocumentsDelta.Deleted);

                Assert.Empty(fieldUpdates.EntryEventRemoveInheritanceFor);
                Assert.Empty(fieldUpdates.StepsRemoveInheritanceFor);
                Assert.Empty(fieldUpdates.DocumentsRemoveInheritanceFor);
            }
        }
    }
}