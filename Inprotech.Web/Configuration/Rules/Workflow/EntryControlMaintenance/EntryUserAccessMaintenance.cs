using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public class EntryUserAccessMaintenance : ISectionMaintenance
    {
        public void ApplyChanges(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            ApplyDelete(entry, newValues, fieldsToUpdate);

            ApplyAdditions(entry, newValues, fieldsToUpdate);
        }

        public void SetDeltaForUpdate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var currentRoleIds = entry.RolesAllowed.Select(_ => _.RoleId).ToArray();
            var currentInheritedRoleIds = entry.RolesAllowed.Where(_ => _.Inherited.GetValueOrDefault()).Select(_ => _.RoleId).ToArray();

            fieldsToUpdate.UserAccessDelta.Added = fieldsToUpdate.UserAccessDelta.Added.Except(currentRoleIds).ToArray();
            fieldsToUpdate.UserAccessDelta.Deleted = fieldsToUpdate.UserAccessDelta.Deleted.Intersect(currentInheritedRoleIds).ToArray();
        }

        public void Reset(DataEntryTask entryToReset, DataEntryTask parentEntry, WorkflowEntryControlSaveModel newValues)
        {
            var existingRoles = entryToReset.RolesAllowed.Select(_ => _.RoleId).ToArray();
            var parentRoles = parentEntry.RolesAllowed.Select(_ => _.RoleId).ToArray();

            newValues.UserAccessDelta.Added.AddRange(parentRoles.Except(existingRoles));
            newValues.UserAccessDelta.Deleted.AddRange(existingRoles.Except(parentRoles));
        }
        
        public void RemoveInheritance(DataEntryTask entryToReset, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            foreach (var role in entryToReset.RolesAllowed.Where(_ => _.Inherited == true && fieldsToUpdate.UserAccessDelta.Deleted.Contains(_.RoleId)))
            {
                role.Inherited = false;
            }
        }

        void ApplyDelete(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var allDeletedRoles = newValues.UserAccessDelta.Deleted.Where(_ => fieldsToUpdate.UserAccessDelta.Deleted.Contains(_));
            foreach (var deleted in allDeletedRoles)
            {
                var role = entry.RolesAllowed.FirstOrDefault(_ => _.RoleId == deleted);
                if (role == null) continue;

                entry.RolesAllowed.Remove(role);
            }
        }

        void ApplyAdditions(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var isUpdatingChildCriteria = Helper.IsUpdateForChildCriteria(entry, newValues);
            var newRoles = newValues.UserAccessDelta.Added.Where(roleId => fieldsToUpdate.UserAccessDelta.Added.Contains(roleId))
                .Select(roleId => new RolesControl(roleId, entry.CriteriaId, entry.Id) {Inherited = isUpdatingChildCriteria});

            entry.RolesAllowed.AddRange(newRoles);
            
            if (!isUpdatingChildCriteria && newValues.ResetInheritance)
            {
                foreach (var r in entry.RolesAllowed)
                {
                    r.Inherited = true;
                }
            }
        }

        public IEnumerable<ValidationError> Validate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues)
        {
            return new ValidationError[0];
        }
    }
}