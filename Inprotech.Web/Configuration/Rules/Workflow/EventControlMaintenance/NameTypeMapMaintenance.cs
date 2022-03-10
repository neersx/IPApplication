using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public class NameTypeMapMaintenance : IEventSectionMaintenance
    {
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;

        public NameTypeMapMaintenance(IWorkflowEventInheritanceService workflowEventInheritanceService)
        {
            _workflowEventInheritanceService = workflowEventInheritanceService;
        }

        public IEnumerable<ValidationError> Validate(WorkflowEventControlSaveModel newValues)
        {
            var delta = newValues.NameTypeMapDelta;
            var models = delta.Added.Union(delta.Updated);
            if (models.Any(_ =>
                               string.IsNullOrEmpty(_.ApplicableNameTypeKey) ||
                               string.IsNullOrEmpty(_.SubstituteNameTypeKey)
                          ))
            {
                yield return ValidationErrors.TopicError("Event Occurrence", "Mandatory Name Type matching field was empty.");
            }
        }

        public void SetChildInheritanceDelta(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            fieldsToUpdate.NameTypeMapsDelta = _workflowEventInheritanceService.GetInheritDelta(() => fieldsToUpdate.NameTypeMapsDelta, @event.NameTypeMapHashList);
        }

        public void ApplyChanges(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var nameTypeMapsDelta = _workflowEventInheritanceService.GetDelta(newValues.NameTypeMapDelta, fieldsToUpdate.NameTypeMapsDelta, _ => _.HashKey(), _ => _.OriginalHashKey);

            var isParentCriteria = @event.CriteriaId == newValues.OriginatingCriteriaId;
            var isInherited = !isParentCriteria || newValues.ResetInheritance;
            if (nameTypeMapsDelta?.Added?.Any() == true)
            {
                if (@event.NameTypeMapHashList().Intersect(nameTypeMapsDelta.Added.Select(_ => _.HashKey())).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate name type maps on criteria {@event.CriteriaId}.");

                var seq = @event.NameTypeMaps != null && @event.NameTypeMaps.Any() ? (short)(@event.NameTypeMaps.Max(_ => _.Sequence) + 1) : (short)0;
                var addedItems = nameTypeMapsDelta.Added;

                foreach (var addedItem in addedItems)
                {
                    var newNameTypeMap = new NameTypeMap(@event, addedItem.ApplicableNameTypeKey, addedItem.SubstituteNameTypeKey, seq);
                    newNameTypeMap.CopyFrom(addedItem, isInherited);
                    @event.NameTypeMaps?.Add(newNameTypeMap);
                    seq++;
                }
            }

            if (nameTypeMapsDelta?.Updated?.Any() == true)
            {
                foreach (var updatedItem in nameTypeMapsDelta.Updated)
                {
                    var nameTypeMap = @event.NameTypeMaps?.SingleOrDefault(_ => (isParentCriteria || _.Inherited) && _.HashKey() == updatedItem.OriginalHashKey);
                    nameTypeMap?.CopyFrom(updatedItem, isInherited);
                }
            }

            if (nameTypeMapsDelta?.Deleted?.Any() == true)
            {
                foreach (var deletedItem in nameTypeMapsDelta.Deleted)
                {
                    var nameTypeMap = @event.NameTypeMaps?.SingleOrDefault(_ => (isParentCriteria || _.Inherited) && _.HashKey() == deletedItem.OriginalHashKey);

                    if (nameTypeMap != null)
                        @event.NameTypeMaps.Remove(nameTypeMap);
                }
            }
        }

        public void RemoveInheritance(ValidEvent @event, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var modifiedItems = fieldsToUpdate.NameTypeMapsDelta.Deleted.Union(fieldsToUpdate.NameTypeMapsDelta.Updated);
            foreach (var dl in @event.NameTypeMaps.Where(_ => _.Inherited && modifiedItems.Contains(_.HashKey())))
            {
                dl.Inherited = false;
            }
        }

        public void Reset(WorkflowEventControlSaveModel newValues, ValidEvent parentValidEvent, ValidEvent validEvent)
        {
            // added or updated
            foreach (var d in parentValidEvent.NameTypeMaps)
            {
                var saveModel = new NameTypeMapSaveModel();
                saveModel.InheritRuleFrom(d);
                var matched = validEvent.NameTypeMaps.SingleOrDefault(_ => _.HashKey() == d.HashKey());
                if (matched != null)
                {
                    saveModel.OriginalHashKey = matched.HashKey();
                    newValues.NameTypeMapDelta.Updated.Add(saveModel);
                }
                else
                {
                    newValues.NameTypeMapDelta.Added.Add(saveModel);
                }
            }

            // delete the rest
            var keepHashKeys = newValues.NameTypeMapDelta.Updated.Select(_ => _.HashKey());
            var deletes = validEvent.NameTypeMaps.Where(_ => !keepHashKeys.Contains(_.HashKey()))
                                    .Select(_ => new NameTypeMapSaveModel { OriginalHashKey = _.HashKey() });
            newValues.NameTypeMapDelta.Deleted.AddRange(deletes);
        }
    }
}
