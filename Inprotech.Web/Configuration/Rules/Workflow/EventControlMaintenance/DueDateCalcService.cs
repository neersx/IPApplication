using System;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public interface IDueDateCalcService
    {
        Delta<int> GetChildInheritanceDelta(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate);
        void ApplyDueDateCalcChanges(int originatingCriteriaId, ValidEvent eventControl, Delta<DueDateCalcSaveModel> dueDateCalcDelta, bool forceInheritance);
    }

    public class DueDateCalcService : IDueDateCalcService
    {
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;
        readonly IDbContext _dbContext;

        public DueDateCalcService(IWorkflowEventInheritanceService workflowEventInheritanceService, IDbContext dbContext)
        {
            _workflowEventInheritanceService = workflowEventInheritanceService;
            _dbContext = dbContext;
        }

        public Delta<int> GetChildInheritanceDelta(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var returnDelta = _workflowEventInheritanceService.GetInheritDelta(() => fieldsToUpdate.DueDateCalcsDelta, @event.DueDateCalcHashList);

            // all jurisdiction-less due date calcs get passed
            if (newValues.DueDateCalcDelta.Added.All(d => string.IsNullOrEmpty(d.JurisdictionId))) return returnDelta;

            var childJurisdiction = _dbContext.Set<Criteria>().Single(c => c.Id == @event.CriteriaId).CountryId;

            if (string.IsNullOrEmpty(childJurisdiction)) return returnDelta;

            // if the criteria has a jurisdiction, only add jurisdiction-less due date calcs
            var dueDateCalcsWithJurisdiction = newValues.DueDateCalcDelta.Added.Where(_ => !string.IsNullOrEmpty(_.JurisdictionId)).Select(_ => _.HashKey());
            returnDelta.Added = returnDelta.Added.Except(dueDateCalcsWithJurisdiction).ToArray();

            return returnDelta;
        }

        public void ApplyDueDateCalcChanges(int originatingCriteriaId, ValidEvent eventControl, Delta<DueDateCalcSaveModel> dueDateCalcDelta, bool forceInheritance)
        {
            var isParentCriteria = eventControl.CriteriaId == originatingCriteriaId;
            var isInherited = !isParentCriteria || forceInheritance;
            if (dueDateCalcDelta?.Added?.Any() == true)
            {
                if (eventControl.DueDateCalcHashList().Intersect(dueDateCalcDelta.Added.Select(_ => _.HashKey())).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate due date calculation (cycle/jurisdiction/from event/relative cycle/period type/period) on criteria {eventControl.CriteriaId}.");

                if (eventControl.DateComparisonHashList().Intersect(dueDateCalcDelta.Added.Select(_ => _.HashKey())).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate date comparison on criteria {eventControl.CriteriaId}.");

                var seq = eventControl.DueDateCalcs != null && eventControl.DueDateCalcs.Any() ? (short) (eventControl.DueDateCalcs.Max(_ => _.Sequence) + 1) : (short) 0;
                var addedItems = dueDateCalcDelta.Added;

                foreach (var addedItem in addedItems)
                {
                    var newDueDateCalc = new DueDateCalc(eventControl, seq);
                    newDueDateCalc.CopyFrom(addedItem, isInherited);
                    eventControl.DueDateCalcs?.Add(newDueDateCalc);

                    seq++;
                }
            }

            if (dueDateCalcDelta?.Updated?.Any() == true)
            {
                foreach (var updatedItem in dueDateCalcDelta.Updated)
                {
                    var dueDateCalc = eventControl.DueDateCalcs?.SingleOrDefault(_ => (isParentCriteria || _.IsInherited) && _.HashKey() == updatedItem.OriginalHashKey);

                    dueDateCalc?.CopyFrom(updatedItem, isInherited);
                }
            }

            if (dueDateCalcDelta?.Deleted?.Any() == true)
            {
                foreach (var deletedItem in dueDateCalcDelta.Deleted)
                {
                    var dueDateCalc = eventControl.DueDateCalcs?.SingleOrDefault(_ => (isParentCriteria || _.IsInherited) && _.HashKey() == deletedItem.OriginalHashKey);

                    if (dueDateCalc != null)
                        eventControl.DueDateCalcs.Remove(dueDateCalc);
                }
            }
        }
    }
}