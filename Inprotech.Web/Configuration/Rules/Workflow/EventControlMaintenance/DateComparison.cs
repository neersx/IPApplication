using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public class DateComparison : IEventSectionMaintenance
    {
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;
        readonly IDueDateCalcService _dueDateCalcService;

        public DateComparison(IWorkflowEventInheritanceService workflowEventInheritanceService, IDueDateCalcService dueDateCalcService)
        {
            _workflowEventInheritanceService = workflowEventInheritanceService;
            _dueDateCalcService = dueDateCalcService;
        }

        public IEnumerable<ValidationError> Validate(WorkflowEventControlSaveModel newValues)
        {
            foreach (var dc in newValues.DateComparisonDelta.Added.Union(newValues.DateComparisonDelta.Updated))
            {
                if (dc.FromEventId == null || dc.RelativeCycle == null || dc.Comparison == null)
                    yield return ValidationErrors.TopicError("dateComparison", "Mandatory field was empty.");

                if (dc.Comparison == "EX" || dc.Comparison == "NE")
                    continue;

                if (dc.CompareSystemDate == true || dc.CompareDate != null)
                    continue;

                if (dc.CompareEventId != null && dc.CompareCycle == null)
                {
                    yield return ValidationErrors.TopicError("dateComparison", "Mandatory field was empty.");
                }
            }
        }

        public void SetChildInheritanceDelta(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            fieldsToUpdate.DateComparisonDelta = _workflowEventInheritanceService.GetInheritDelta(() => fieldsToUpdate.DateComparisonDelta, @event.DateComparisonHashList);
        }

        public void ApplyChanges(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var delta = _workflowEventInheritanceService.GetDelta(newValues.DateComparisonDelta, fieldsToUpdate.DateComparisonDelta, _ => _.HashKey(), _ => _.OriginalHashKey);
            _dueDateCalcService.ApplyDueDateCalcChanges(newValues.OriginatingCriteriaId, @event, new Delta<DueDateCalcSaveModel>
            {
                Added = delta.Added?.Cast<DueDateCalcSaveModel>().ToArray(),
                Updated = delta.Updated?.Cast<DueDateCalcSaveModel>().ToArray(),
                Deleted = delta.Deleted?.Cast<DueDateCalcSaveModel>().ToArray()
            }, newValues.ResetInheritance);
        }

        public void RemoveInheritance(ValidEvent @event, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var modifiedItems = fieldsToUpdate.DateComparisonDelta.Deleted.Union(fieldsToUpdate.DateComparisonDelta.Updated);
            foreach (var ddc in @event.DueDateCalcs.Where(_ => _.IsInherited && _.IsDateComparison && modifiedItems.Contains(_.HashKey())))
            {
                ddc.Inherited = 0;
            }
        }

        public void Reset(WorkflowEventControlSaveModel newValues, ValidEvent parentValidEvent, ValidEvent validEvent)
        {
            // added or updated
            foreach (var d in parentValidEvent.DueDateCalcs.AsQueryable().WhereDateComparison())
            {
                var saveModel = new DateComparisonSaveModel();
                saveModel.InheritRuleFrom(d);
                var matched = validEvent.DueDateCalcs.SingleOrDefault(_ => _.HashKey() == d.HashKey());
                if (matched != null)
                {
                    saveModel.OriginalHashKey = matched.HashKey();
                    newValues.DateComparisonDelta.Updated.Add(saveModel);
                }
                else
                {
                    newValues.DateComparisonDelta.Added.Add(saveModel);
                }
            }

            // delete the rest
            var keepHashKeys = newValues.DateComparisonDelta.Updated.Select(_ => _.HashKey());
            var deletes = validEvent.DueDateCalcs.AsQueryable().WhereDateComparison().Where(_ => !keepHashKeys.Contains(_.HashKey()))
                                    .Select(_ => new DateComparisonSaveModel { OriginalHashKey = _.HashKey() });
            newValues.DateComparisonDelta.Deleted.AddRange(deletes);
        }
    }
}