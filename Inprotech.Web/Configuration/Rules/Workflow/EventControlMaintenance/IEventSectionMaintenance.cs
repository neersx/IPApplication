using System.Collections.Generic;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public interface IEventSectionMaintenance
    {
        IEnumerable<ValidationError> Validate(WorkflowEventControlSaveModel newValues);

        /// <summary>
        /// Compare fields to update with event to determine appropriate items to save to child rule
        /// </summary>
        /// <param name="event"></param>
        /// <param name="newValues"></param>
        /// <param name="fieldsToUpdate"></param>
        void SetChildInheritanceDelta(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate);

        void ApplyChanges(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate);

        /// <summary>
        /// // When not applying to children, remove inheritance flag for updated/deleted items
        /// </summary>
        /// <param name="event"></param>
        /// <param name="fieldsToUpdate"></param>
        void RemoveInheritance(ValidEvent @event, EventControlFieldsToUpdate fieldsToUpdate);

        void Reset(WorkflowEventControlSaveModel newValues, ValidEvent parentValidEvent, ValidEvent validEvent);
    }
}