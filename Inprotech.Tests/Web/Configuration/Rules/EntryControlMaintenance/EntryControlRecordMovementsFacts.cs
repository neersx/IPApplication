using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance
{
    public class EntryControlRecordMovementsFacts : FactBase
    {
        [Fact]
        public void SetsEventMovements()
        {
            var move1 = new EntryEventMovementsBase(10, 11);
            var move2 = new EntryEventMovementsBase(100);
            var updates = new WorkflowEntryControlSaveModel
            {
                EntryEventsMoved = new List<EntryEventMovementsBase> {move1, move2}
            };

            var recordMovements = new EntryControlRecordMovements(null, updates);

            Assert.Equal(2, recordMovements.EntryEventsMoved.Count);
            Assert.Equal(10, recordMovements.EntryEventsMoved.First().EventId);
            Assert.Equal(11, recordMovements.EntryEventsMoved.First().PrevEventId.Value);

            Assert.Equal(100, recordMovements.EntryEventsMoved.Skip(1).First().EventId);
            Assert.False(recordMovements.EntryEventsMoved.Skip(1).First().PrevEventId.HasValue);
        }

        [Fact]
        public void SetsStepMovementsWithExistingStepHash()
        {
            var entry = new DataEntryTaskBuilder().BuildWithSteps(Db, 3);
            var firstStep = entry.WorkflowWizard.TopicControls.First();
            var lastStep = entry.WorkflowWizard.TopicControls.Last();

            var move1 = new StepMovements(firstStep.Id, lastStep.Id.ToString());

            var updates = new WorkflowEntryControlSaveModel
            {
                StepsMoved = new List<StepMovements> {move1}
            };

            var recordMovements = new EntryControlRecordMovements(entry, updates);

            Assert.Single(recordMovements.StepMovements);
            Assert.Equal(firstStep.HashCode(), recordMovements.StepMovements.First().OriginalStepHashCode);
            Assert.Equal(lastStep.HashCode(), recordMovements.StepMovements.First().PrevStepHashCode.Value);
        }

        [Fact]
        public void SetsStepMovementsWithNewlyAddedStepHash()
        {
            var entry = new DataEntryTaskBuilder().BuildWithSteps(Db, 3);
            var firstStep = entry.WorkflowWizard.TopicControls.First();
            var lastStep = entry.WorkflowWizard.TopicControls.Last();

            var move1 = new StepMovements(firstStep.Id, "A");
            var move2 = new StepMovements(lastStep.Id);

            var stepAdded = new StepDelta("new Step", "of some type") {NewItemId = "A"};
            var updates = new WorkflowEntryControlSaveModel
            {
                StepsDelta = new Delta<StepDelta>
                {
                    Added = new List<StepDelta> {stepAdded}
                },
                StepsMoved = new List<StepMovements> {move1, move2}
            };

            var recordMovements = new EntryControlRecordMovements(entry, updates);

            Assert.Equal(2, recordMovements.StepMovements.Count);
            Assert.Equal(firstStep.HashCode(), recordMovements.StepMovements.First().OriginalStepHashCode);
            Assert.Equal(stepAdded.HashCode(), recordMovements.StepMovements.First().PrevStepHashCode.Value);

            Assert.Equal(lastStep.HashCode(), recordMovements.StepMovements.Skip(1).First().OriginalStepHashCode);
            Assert.False(recordMovements.StepMovements.Skip(1).First().PrevStepHashCode.HasValue);
        }
    }
}