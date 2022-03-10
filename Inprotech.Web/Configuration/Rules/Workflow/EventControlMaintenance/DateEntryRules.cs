using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public class DateEntryRules : IEventSectionMaintenance
    {
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;

        public DateEntryRules(IWorkflowEventInheritanceService workflowEventInheritanceService)
        {
            _workflowEventInheritanceService = workflowEventInheritanceService;
        }

        public IEnumerable<ValidationError> Validate(WorkflowEventControlSaveModel newValues)
        {
            var delta = newValues.DatesLogicDelta;
            var models = delta.Added.Union(delta.Updated);
            if (models.Any(_ =>
                               string.IsNullOrEmpty(_.Operator) ||
                               _.CompareEventId == null ||
                               _.RelativeCycle == null ||
                               _.DisplayErrorFlag == null ||
                               string.IsNullOrEmpty(_.ErrorMessage)
                          ))
            {
                yield return ValidationErrors.TopicError("Dates Logic", "Mandatory field was empty.");
            }
        }
        
        public void SetChildInheritanceDelta(ValidEvent childEvent, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            fieldsToUpdate.DatesLogicDelta = _workflowEventInheritanceService.GetInheritDelta(() => fieldsToUpdate.DatesLogicDelta, childEvent.DatesLogicHashList);
        }

        public void ApplyChanges(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var datesLogicDelta = _workflowEventInheritanceService.GetDelta(newValues.DatesLogicDelta, fieldsToUpdate.DatesLogicDelta, _ => _.HashKey(), _ => _.OriginalHashKey);
            
            var isParentCriteria = @event.CriteriaId == newValues.OriginatingCriteriaId;
            var isInherited = !isParentCriteria || newValues.ResetInheritance;
            if (datesLogicDelta?.Added?.Any() == true)
            {
                if (@event.DatesLogicHashList().Intersect(datesLogicDelta.Added.Select(_ => _.HashKey())).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate dates logic on criteria {@event.CriteriaId}.");

                var seq = @event.DatesLogic != null && @event.DatesLogic.Any() ? (short)(@event.DatesLogic.Max(_ => _.Sequence) + 1) : (short)0;
                var addedItems = datesLogicDelta.Added;

                foreach (var addedItem in addedItems)
                {
                    var newDatesLogic = new DatesLogic(@event, seq);
                    newDatesLogic.CopyFrom(addedItem, isInherited);
                    @event.DatesLogic?.Add(newDatesLogic);
                    seq++;
                }
            }

            if (datesLogicDelta?.Updated?.Any() == true)
            {
                foreach (var updatedItem in datesLogicDelta.Updated)
                {
                    var datesLogic = @event.DatesLogic?.SingleOrDefault(_ => (isParentCriteria || _.IsInherited) && _.HashKey() == updatedItem.OriginalHashKey);

                    datesLogic?.CopyFrom(updatedItem, isInherited);
                }
            }

            if (datesLogicDelta?.Deleted?.Any() == true)
            {
                foreach (var deletedItem in datesLogicDelta.Deleted)
                {
                    var datesLogic = @event.DatesLogic?.SingleOrDefault(_ => (isParentCriteria || _.IsInherited) && _.HashKey() == deletedItem.OriginalHashKey);

                    if (datesLogic != null)
                        @event.DatesLogic.Remove(datesLogic);
                }
            }
        }

        public void RemoveInheritance(ValidEvent eventToReset, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var modifiedItems = fieldsToUpdate.DatesLogicDelta.Deleted.Union(fieldsToUpdate.DatesLogicDelta.Updated);
            foreach (var dl in eventToReset.DatesLogic.Where(_ => _.IsInherited && modifiedItems.Contains(_.HashKey())))
            {
                dl.Inherited = 0;
            }
        }

        public void Reset(WorkflowEventControlSaveModel newValues, ValidEvent parentValidEvent, ValidEvent validEvent)
        {
            // added or updated
            foreach (var d in parentValidEvent.DatesLogic)
            {
                var saveModel = new DatesLogicSaveModel();
                saveModel.InheritRuleFrom(d);
                var matched = validEvent.DatesLogic.SingleOrDefault(_ => _.HashKey() == d.HashKey());
                if (matched != null)
                {
                    saveModel.OriginalHashKey = matched.HashKey();
                    newValues.DatesLogicDelta.Updated.Add(saveModel);
                }
                else
                {
                    newValues.DatesLogicDelta.Added.Add(saveModel);
                }
            }

            // delete the rest
            var keepHashKeys = newValues.DatesLogicDelta.Updated.Select(_ => _.HashKey());
            var deletes = validEvent.DatesLogic.Where(_ => !keepHashKeys.Contains(_.HashKey()))
                                    .Select(_ => new DatesLogicSaveModel { OriginalHashKey = _.HashKey() });
            newValues.DatesLogicDelta.Deleted.AddRange(deletes);
        }
    }
}
