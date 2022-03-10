using System.Collections.Generic;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public interface ISectionMaintenance
    {
        IEnumerable<ValidationError> Validate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues);

        void SetDeltaForUpdate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate);

        void ApplyChanges(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate);

        /// <summary>
        /// // When not applying to children, remove inheritance flag for updated/deleted items
        /// </summary>
        /// <param name="entry"></param>
        /// <param name="fieldsToUpdate"></param>
        void RemoveInheritance(DataEntryTask entry, EntryControlFieldsToUpdate fieldsToUpdate);

        /// <summary>
        /// Reset section to fully inherit from parent
        /// </summary>
        /// <param name="entryToReset"></param>
        /// <param name="parentEntry"></param>
        void Reset(DataEntryTask entryToReset, DataEntryTask parentEntry, WorkflowEntryControlSaveModel newValues);
    }
}