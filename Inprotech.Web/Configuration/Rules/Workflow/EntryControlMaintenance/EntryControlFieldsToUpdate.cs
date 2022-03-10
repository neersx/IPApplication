using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    // Property names must match DataEntryTask properties
    public class EntryControlFieldsToUpdate : ICloneable
    {
        bool _dimEventNo = true;
        bool _displayEventNo = true;
        bool _hideEventNo = true;

        public EntryControlFieldsToUpdate(DataEntryTask initialEntry, WorkflowEntryControlSaveModel saveModel)
        {
            if (initialEntry.IsSeparator)
            {
                var fields = typeof(EntryControlFieldsToUpdate).GetProperties().Where(_ => _.PropertyType == typeof(bool));
                foreach (var field in fields)
                {
                    field.SetValue(this, false);
                }

                Description = true;

                saveModel.EntryEventDelta = new Delta<EntryEventDelta>();
                saveModel.StepsDelta = new Delta<StepDelta>();
                saveModel.DocumentsDelta = new Delta<EntryDocumentDelta>();
            }

            EntryEventsDelta = new Delta<int>
            {
                Added = saveModel.EntryEventDelta.Added.Select(_ => _.EventId).ToArray(),
                Updated = saveModel.EntryEventDelta.Updated.Where(_ => _.PreviousEventId.HasValue).Select(_ => _.PreviousEventId.Value).ToArray(),
                Deleted = saveModel.EntryEventDelta.Deleted.Select(_ => _.EventId).ToArray()
            };

            StepsDelta = new Delta<StepHashes>
            {
                Added = new List<StepHashes>(),
                Updated = new List<StepHashes>(),
                Deleted = new List<StepHashes>()
            };

            DocumentsDelta = new Delta<short>
            {
                Added = saveModel.DocumentsDelta.Added.Select(_ => _.DocumentId).ToArray(),
                Updated = saveModel.DocumentsDelta.Updated.Where(_ => _.PreviousDocumentId.HasValue).Select(_ => _.PreviousDocumentId.Value).ToArray(),
                Deleted = saveModel.DocumentsDelta.Deleted.Select(_ => _.DocumentId).ToArray()
            };

            UserAccessDelta = saveModel.UserAccessDelta;

            EntryEventRemoveInheritanceFor = new List<int>();
            StepsRemoveInheritanceFor = new List<int>();
            DocumentsRemoveInheritanceFor = new List<short>();

            SetStepToUpdate(initialEntry, saveModel);
        }

        public bool Description { get; set; } = true;

        public bool UserInstruction { get; set; } = true;

        public bool OfficialNumberTypeId { get; set; } = true;

        public bool FileLocationId { get; set; } = true;

        public bool AtLeastOneFlag { get; set; } = true;

        public bool ShouldPoliceImmediate { get; set; } = true;

        public bool DisplayEventNo
        {
            get { return _hideEventNo && _displayEventNo && _dimEventNo; }
            set { _displayEventNo = value; }
        }

        public bool HideEventNo
        {
            get { return _hideEventNo && _displayEventNo && _dimEventNo; }
            set { _hideEventNo = value; }
        }

        public bool DimEventNo
        {
            get { return _hideEventNo && _displayEventNo && _dimEventNo; }
            set { _dimEventNo = value; }
        }

        public bool CaseStatusCodeId { get; set; } = true;

        public bool RenewalStatusId { get; set; } = true;

        public Delta<int> EntryEventsDelta { get; set; }

        public Delta<short> DocumentsDelta { get; set; }
        
        public Delta<StepHashes> StepsDelta { get; set; }

        public Delta<int> UserAccessDelta { get; set; }

        public ICollection<int> EntryEventRemoveInheritanceFor { get; set; }

        public ICollection<int> StepsRemoveInheritanceFor { get; set; }

        public ICollection<short> DocumentsRemoveInheritanceFor { get; set; }

        public ICollection<short> UserAccessRemoveInheritanceFor { get; set; }
        
        public static IEnumerable<PropertyInfo> All
        {
            get
            {
                var fields = typeof(EntryControlFieldsToUpdate).GetProperties().Where(_ => _.PropertyType == typeof(bool));
                return fields;
            }
        }

        public object Clone()
        {
            var newObject = (EntryControlFieldsToUpdate) MemberwiseClone();

            newObject.EntryEventsDelta = (Delta<int>) EntryEventsDelta.Clone();

            newObject.StepsDelta = (Delta<StepHashes>) StepsDelta.Clone();

            newObject.DocumentsDelta = (Delta<short>) DocumentsDelta.Clone();

            newObject.UserAccessDelta = (Delta<int>) UserAccessDelta.Clone();

            return newObject;
        }

        public void SetStepToUpdate(DataEntryTask initialEntry, WorkflowEntryControlSaveModel saveModel)
        {
            int? relativeHashCode = null;

            foreach (var step in saveModel.StepsDelta.Added)
            {
                if (!string.IsNullOrEmpty(step.RelativeId))
                {
                    int relativeIdInt;
                    IFlattenTopic correspondingStep;
                    if (int.TryParse(step.RelativeId, out relativeIdInt))
                        correspondingStep = saveModel.StepsDelta.Updated.SingleOrDefault(_ => _.Id == relativeIdInt) ?? (IFlattenTopic) GetExistingStep(initialEntry, relativeIdInt);
                    else
                        correspondingStep = saveModel.StepsDelta.Added.SingleOrDefault(_ => _.NewItemId == step.RelativeId);

                    relativeHashCode = correspondingStep?.HashCode();
                }

                StepsDelta.Added.Add(StepHashes.StepAddition(step.HashCode(), relativeHashCode));
            }

            foreach (var step in saveModel.StepsDelta.Updated)
            {
                if (!step.Id.HasValue)
                    continue;

                var correspondingStep = GetExistingStep(initialEntry, step.Id.Value);
                if (correspondingStep == null)
                    continue;

                StepsDelta.Updated.Add(StepHashes.StepUpdation(correspondingStep.HashCode(), step.HashCode()));
            }

            foreach (var step in saveModel.StepsDelta.Deleted)
            {
                if (!step.Id.HasValue)
                    continue;

                var correspondingStep = GetExistingStep(initialEntry, step.Id.Value);
                if (correspondingStep == null)
                    continue;

                StepsDelta.Deleted.Add(StepHashes.StepDeletion(correspondingStep.HashCode()));
            }
        }

        TopicControl GetExistingStep(DataEntryTask initialEntry, int id)
        {
            return initialEntry.WorkflowWizard?.TopicControls.SingleOrDefault(_ => _.Id == id);
        }
    }

    public class StepHashes : ICloneable
    {
        public StepHashes(int? originalHashCode, int? newHashCode = null, int? relativeHashCode = null)
        {
            OriginalHashCode = originalHashCode;
            NewHashCode = newHashCode;
            RelativeHashCode = relativeHashCode;
        }

        public int? OriginalHashCode { get; set; }

        public int? NewHashCode { get; set; }

        public int? RelativeHashCode { get; set; }

        public object Clone()
        {
            return (StepHashes) MemberwiseClone();
        }

        public static StepHashes StepAddition(int newHashCode, int? relativeHashCode = null)
        {
            return new StepHashes(null, newHashCode, relativeHashCode);
        }

        public static StepHashes StepUpdation(int originalHashCode, int? newHashCode = null)
        {
            return new StepHashes(originalHashCode, newHashCode);
        }

        public static StepHashes StepDeletion(int originalHashCode)
        {
            return new StepHashes(originalHashCode);
        }
    }
}