using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public class RequiredEventRules : IEventSectionMaintenance
    {
        public IEnumerable<ValidationError> Validate(WorkflowEventControlSaveModel newValues)
        {
            return new ValidationError[0];
        }

        public void SetChildInheritanceDelta(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            fieldsToUpdate.RequiredEventRulesDelta = new Delta<int>
            {
                Added = fieldsToUpdate.RequiredEventRulesDelta.Added?.Except(@event.GetRequiredEventKeys(false)).ToArray(),
                Deleted = fieldsToUpdate.RequiredEventRulesDelta.Deleted?.Intersect(@event.GetRequiredEventKeys(true)).ToArray(),
            };
        }

        public void ApplyChanges(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var isParentCriteria = @event.CriteriaId == newValues.OriginatingCriteriaId;
            if (fieldsToUpdate.RequiredEventRulesDelta?.Added?.Any() == true)
            {
                if (@event.GetRequiredEventKeys(false).Intersect(fieldsToUpdate.RequiredEventRulesDelta.Added).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate Required Event on criteria {@event.CriteriaId}.");
                
                var isInherited = !isParentCriteria || newValues.ResetInheritance;

                foreach (var addedItem in fieldsToUpdate.RequiredEventRulesDelta.Added)
                {
                    var newRequiredEvent = new RequiredEventRule(@event) { RequiredEventId = addedItem, Inherited = isInherited };
                    @event.RequiredEvents?.Add(newRequiredEvent);
                }
            }

            if (fieldsToUpdate.RequiredEventRulesDelta?.Deleted?.Any() == true)
            {
                foreach (var deletedItem in fieldsToUpdate.RequiredEventRulesDelta.Deleted)
                {
                    var requiredEvent = @event.RequiredEvents?.SingleOrDefault(_ => (isParentCriteria || _.Inherited) && _.RequiredEventId == deletedItem);

                    if (requiredEvent != null)
                        @event.RequiredEvents.Remove(requiredEvent);
                }
            }

            if (isParentCriteria && newValues.ResetInheritance && @event.RequiredEvents != null)
            {
                foreach (var d in @event.RequiredEvents)
                    d.Inherited = true;
            }
        }

        public void RemoveInheritance(ValidEvent eventToReset, EventControlFieldsToUpdate fieldsToUpdate)
        {
            if (fieldsToUpdate.RequiredEventRulesDelta?.Deleted?.Any() == true)
            {
                foreach (var e in eventToReset.RequiredEvents.AsQueryable().Where(d => d.Inherited && fieldsToUpdate.RequiredEventRulesDelta.Deleted.Contains(d.RequiredEventId)))
                {
                    e.Inherited = false;
                }
            }
        }

        public void Reset(WorkflowEventControlSaveModel newValues, ValidEvent parentValidEvent, ValidEvent validEvent)
        {
            var parentRequiredEventRules = parentValidEvent.RequiredEvents.AsQueryable().Select(_ => _.RequiredEventId);
            var existingRequiredEventRules = validEvent.RequiredEvents.AsQueryable().Select(_ => _.RequiredEventId);

            newValues.RequiredEventRulesDelta.Added.AddRange(parentRequiredEventRules.Except(existingRequiredEventRules));
            newValues.RequiredEventRulesDelta.Deleted.AddRange(existingRequiredEventRules.Except(parentRequiredEventRules));
        }
    }
}
