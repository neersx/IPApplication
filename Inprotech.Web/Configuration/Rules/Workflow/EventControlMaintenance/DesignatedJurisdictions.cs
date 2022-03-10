using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using model=InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public class DesignatedJurisdictions : IEventSectionMaintenance
    {
        readonly IDbContext _dbContext;

        public DesignatedJurisdictions(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<ValidationError> Validate(WorkflowEventControlSaveModel newValues)
        {
            if (newValues.DesignatedJurisdictionsDelta.Added.Any())
            {
                var criteria = _dbContext.Set<Criteria>().Single(_ => _.Id == newValues.OriginatingCriteriaId);
                if (!criteria.Country.IsGroup)
                    yield return ValidationErrors.TopicError("designatedJurisdictions", "Designated Jurisdictions can only be added to Workflow rules of Group Countries.");

                var applicableCountries = _dbContext.Set<CountryGroup>().Where(_ => _.Id == criteria.CountryId).Select(_ => _.MemberCountry);
                if (newValues.DesignatedJurisdictionsDelta.Added.Any(_ => !applicableCountries.Contains(_)))
                    yield return ValidationErrors.TopicError("designatedJurisdictions", $"Only member countries of {criteria.Country.Name} can be added to Designated Jurisdictions");
            }
        }

        public void SetChildInheritanceDelta(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var criteria = _dbContext.Set<Criteria>().Single(_ => _.Id == @event.CriteriaId);
            if (string.IsNullOrEmpty(criteria.CountryId) || !criteria.Country.IsGroup)
            {
                // don't pass down anything if child is not a group country criteria
                fieldsToUpdate.DesignatedJurisdictionsDelta = new Delta<string>();
                return;
            }

            fieldsToUpdate.DesignatedJurisdictionsDelta = new Delta<string>
            {
                Added = fieldsToUpdate.DesignatedJurisdictionsDelta.Added?.Except(@event.DueDateCalcs.GetDesignatedJurisdictions(false)).ToArray(),
                Deleted = fieldsToUpdate.DesignatedJurisdictionsDelta.Deleted?.Intersect(@event.DueDateCalcs.GetDesignatedJurisdictions(true)).ToArray()
            };
        }

        public void ApplyChanges(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            if (fieldsToUpdate.DesignatedJurisdictionsDelta.Added.Any() && @event.CheckCountryFlag == null && fieldsToUpdate.CheckCountryFlag == false)
            {
                // force update the country flag since we'll be adding designated jurisdictions
                @event.CheckCountryFlag = newValues.CheckCountryFlag;
            }

            var deletedCount = fieldsToUpdate.DesignatedJurisdictionsDelta.Deleted.Count;
            var existingCount = @event.DueDateCalcs.GetDesignatedJurisdictions(false).Count;
            if (!fieldsToUpdate.DesignatedJurisdictionsDelta.Added.Any() && deletedCount == existingCount)
            {
                // since we're deleting all the designated Jurisdictions, clear the CheckCountryFlag.
                @event.CheckCountryFlag = null;
                fieldsToUpdate.CheckCountryFlag = false;
            }

            if (newValues.CheckCountryFlag == null && deletedCount < existingCount)
            {
                // don't clear the flag if there are going to be countries remaining.
                fieldsToUpdate.CheckCountryFlag = false;
            }

            var isParentCriteria = @event.CriteriaId == newValues.OriginatingCriteriaId;
            if (fieldsToUpdate.DesignatedJurisdictionsDelta?.Added?.Any() == true)
            {
                if (@event.DueDateCalcs.Where(_ => _.IsDesignatedJurisdiction).Select(_ => _.JurisdictionId).Intersect(fieldsToUpdate.DesignatedJurisdictionsDelta.Added).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate Designated Jurisdiction on criteria {@event.CriteriaId}.");

                var seq = @event.DueDateCalcs != null && @event.DueDateCalcs.Any() ? (short)(@event.DueDateCalcs.Max(_ => _.Sequence) + 1) : (short)0;
                var isInherited = !isParentCriteria || newValues.ResetInheritance;

                foreach (var addedItem in fieldsToUpdate.DesignatedJurisdictionsDelta.Added)
                {
                    var newDesignatedJurisdiction = new model.DueDateCalc(@event, seq) { JurisdictionId = addedItem, IsInherited = isInherited };
                    @event.DueDateCalcs?.Add(newDesignatedJurisdiction);
                    seq++;
                }
            }

            if (fieldsToUpdate.DesignatedJurisdictionsDelta?.Deleted?.Any() == true)
            {
                foreach (var deletedItem in fieldsToUpdate.DesignatedJurisdictionsDelta.Deleted)
                {
                    var dueDateCalc = @event.DueDateCalcs?.SingleOrDefault(_ => (isParentCriteria || _.IsInherited) && _.IsDesignatedJurisdiction && _.JurisdictionId == deletedItem);

                    if (dueDateCalc != null)
                        @event.DueDateCalcs.Remove(dueDateCalc);
                }
            }

            if (isParentCriteria && newValues.ResetInheritance && @event.DueDateCalcs != null)
            {
                foreach (var d in @event.DueDateCalcs.AsQueryable().WhereDesignatedJurisdiction())
                    d.IsInherited = true;
            }
        }

        public void RemoveInheritance(ValidEvent eventToReset, EventControlFieldsToUpdate fieldsToUpdate)
        {
            if (fieldsToUpdate.DesignatedJurisdictionsDelta?.Deleted?.Any() == true)
            {
                foreach (var dj in eventToReset.DueDateCalcs.AsQueryable().WhereDesignatedJurisdiction().Where(d => d.IsInherited && fieldsToUpdate.DesignatedJurisdictionsDelta.Deleted.Contains(d.JurisdictionId)))
                {
                    dj.IsInherited = false;
                }
            }
        }

        public void Reset(WorkflowEventControlSaveModel newValues, ValidEvent parentValidEvent, ValidEvent validEvent)
        {
            var parentJurisdictions = new string[0];

            var country = _dbContext.Set<Criteria>().Single(_ => _.Id == validEvent.CriteriaId).Country;
            if (country != null && country.IsGroup)
            {
                // only reset from parent if group country
                parentJurisdictions = parentValidEvent.DueDateCalcs.AsQueryable().WhereDesignatedJurisdiction().Select(_ => _.JurisdictionId).ToArray();
            }

            var existingJurisdictions = validEvent.DueDateCalcs.AsQueryable().WhereDesignatedJurisdiction().Select(_ => _.JurisdictionId);

            newValues.DesignatedJurisdictionsDelta.Added.AddRange(parentJurisdictions.Except(existingJurisdictions));
            newValues.DesignatedJurisdictionsDelta.Deleted.AddRange(existingJurisdictions.Except(parentJurisdictions));
        }
    }
}
