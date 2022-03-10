using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public class EntryControlRecordMovements
    {
        public EntryControlRecordMovements(DataEntryTask entry, WorkflowEntryControlSaveModel saveModel)
        {
            EntryEventsMoved = saveModel.EntryEventsMoved.Select(_ => new EntryEventMovements(_)).ToList();

            StepMovements = new List<StepMovementHashes>();
            StepMovements.AddRange(GetStepMovementHashes(entry, saveModel).ToArray());
        }

        public List<EntryEventMovements> EntryEventsMoved { get; set; }

        public List<StepMovementHashes> StepMovements { get; set; }

        static TopicControl GetExistingStep(DataEntryTask initialEntry, int id)
        {
            return initialEntry.WorkflowWizard?.TopicControls.SingleOrDefault(_ => _.Id == id);
        }

        static IEnumerable<StepMovementHashes> GetStepMovementHashes(DataEntryTask entry, WorkflowEntryControlSaveModel newValues)
        {
            foreach (var stepMoved in newValues.StepsMoved)
            {
                var movedStep = GetExistingStep(entry, stepMoved.StepId);
                if (movedStep == null)
                    continue;

                if (string.IsNullOrWhiteSpace(stepMoved.PrevStepIdentifier))
                {
                    yield return new StepMovementHashes(movedStep.HashCode());
                    continue;
                }

                int prevStepId;
                int? prevStepHashCode;
                if (int.TryParse(stepMoved.PrevStepIdentifier, out prevStepId))
                {
                    var prevStep = GetExistingStep(entry, prevStepId);

                    if (prevStep == null)
                        continue;

                    prevStepHashCode = prevStep.HashCode();
                }
                else
                {
                    var prevStep = newValues.StepsDelta.Added.SingleOrDefault(_ => _.NewItemId == stepMoved.PrevStepIdentifier);
                    if (prevStep == null)
                        continue;

                    prevStepHashCode = prevStep.HashCode();
                }

                yield return new StepMovementHashes(movedStep.HashCode(), prevStepHashCode);
            }
        }
    }

    public class StepMovementHashes
    {
        public StepMovementHashes(int originalStepHashCode, int? prevStepHashCode = null, int? nextStepHashCode = null)
        {
            OriginalStepHashCode = originalStepHashCode;
            PrevStepHashCode = prevStepHashCode;
            NextStepHashCode = nextStepHashCode;
        }

        public int OriginalStepHashCode { get; set; }

        public int? PrevStepHashCode { get; set; }

        public int? NextStepHashCode { get; set; }
    }

    public class EntryEventMovements : EntryEventMovementsBase
    {
        public EntryEventMovements(EntryEventMovementsBase baseObj) : base(baseObj.EventId, baseObj.PrevEventId)
        {
        }
        internal int? NextEventId { get; set; }
    }
}