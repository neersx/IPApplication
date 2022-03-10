using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public class DueDateCalcMaintenance : IEventSectionMaintenance
    {
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;
        readonly IDueDateCalcService _dueDateCalcService;

        public DueDateCalcMaintenance(IWorkflowEventInheritanceService workflowEventInheritanceService, IDueDateCalcService dueDateCalcService)
        {
            _workflowEventInheritanceService = workflowEventInheritanceService;
            _dueDateCalcService = dueDateCalcService;
        }

        public IEnumerable<ValidationError> Validate(WorkflowEventControlSaveModel newValues)
        {
            var dueDateCalcs = newValues.DueDateCalcDelta.Added.Union(newValues.DueDateCalcDelta.Updated);
            foreach (var d in dueDateCalcs)
            {
                if (d.Operator == null || d.FromEventId == null || d.RelativeCycle == null || d.Cycle == null)
                    yield return ValidationErrors.TopicError("dueDateCalc", "Mandatory field was empty (Operator/Period/PeriodType/FromEvent/RelativeCycle).");

                if (!new[] { "E", "1", "2", "3" }.Contains(d.PeriodType))
                {
                    if (d.PeriodType == null || d.Period == null)
                    {
                        yield return ValidationErrors.TopicError("dueDateCalc", "Mandatory field was empty (Operator/Period/PeriodType/FromEvent/RelativeCycle).");
                    }
                }
            }
        }

        public void SetChildInheritanceDelta(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            fieldsToUpdate.DueDateCalcsDelta = _dueDateCalcService.GetChildInheritanceDelta(@event, newValues, fieldsToUpdate);
        }

        public void ApplyChanges(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var delta = _workflowEventInheritanceService.GetDelta(newValues.DueDateCalcDelta, fieldsToUpdate.DueDateCalcsDelta, _ => _.HashKey(), _ => _.OriginalHashKey);
            _dueDateCalcService.ApplyDueDateCalcChanges(newValues.OriginatingCriteriaId, @event, delta, newValues.ResetInheritance);
        }

        public void RemoveInheritance(ValidEvent @event, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var modifiedItems = fieldsToUpdate.DueDateCalcsDelta.Deleted.Union(fieldsToUpdate.DueDateCalcsDelta.Updated);
            foreach (var ddc in @event.DueDateCalcs.Where(_ => _.IsInherited && modifiedItems.Contains(_.HashKey())))
            {
                ddc.Inherited = 0;
            }
        }

        public void Reset(WorkflowEventControlSaveModel newValues, ValidEvent parentValidEvent, ValidEvent validEvent)
        {
            // added or updated
            foreach (var d in parentValidEvent.DueDateCalcs.AsQueryable().WhereDueDateCalc())
            {
                var saveModel = new DueDateCalcSaveModel();
                saveModel.InheritRuleFrom(d);
                var matched = validEvent.DueDateCalcs.SingleOrDefault(_ => _.HashKey() == d.HashKey());
                if (matched != null)
                {
                    saveModel.OriginalHashKey = matched.HashKey();
                    newValues.DueDateCalcDelta.Updated.Add(saveModel);
                }
                else
                {
                    newValues.DueDateCalcDelta.Added.Add(saveModel);
                }
            }

            // delete the rest
            var keepHashKeys = newValues.DueDateCalcDelta.Updated.Select(_ => _.HashKey());
            var deletes = validEvent.DueDateCalcs.AsQueryable().WhereDueDateCalc().Where(_ => !keepHashKeys.Contains(_.HashKey()))
                                   .Select(_ => new DueDateCalcSaveModel { OriginalHashKey = _.HashKey() });
            newValues.DueDateCalcDelta.Deleted.AddRange(deletes);
        }
    }
}
