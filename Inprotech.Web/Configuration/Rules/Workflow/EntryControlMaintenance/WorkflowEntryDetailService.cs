using System.Collections.Generic;
using System.Linq;
using AutoMapper;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public interface IWorkflowEntryDetailService
    {
        IEnumerable<ValidationError> ValidateChange(DataEntryTask entry, WorkflowEntryControlSaveModel newValues);
        void UpdateEntryDetail(DataEntryTask entryToUpdate, WorkflowEntryControlSaveModel newValues);
    }

    internal class WorkflowEntryDetailService : IWorkflowEntryDetailService
    {
        readonly IDbContext _dbContext;
        readonly IDescriptionValidator _descriptionValidator;
        readonly IMapper _mapper;
        readonly IEnumerable<IReorderableSection> _reorderableSections;
        readonly IInheritance _inheritance;
        readonly IEnumerable<ISectionMaintenance> _sectionMaintenances;

        public WorkflowEntryDetailService(IDbContext dbContext,
                                          IMapper mapper,
                                          IDescriptionValidator descriptionValidator,
                                          IEnumerable<ISectionMaintenance> sectionMaintenances,
                                          IEnumerable<IReorderableSection> reorderableSections,
                                          IInheritance inheritance)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _descriptionValidator = descriptionValidator;
            _sectionMaintenances = sectionMaintenances;
            _reorderableSections = reorderableSections;
            _inheritance = inheritance;
        }

        public IEnumerable<ValidationError> ValidateChange(DataEntryTask entry, WorkflowEntryControlSaveModel newValues)
        {
            var descriptionError = _descriptionValidator.Validate(entry.CriteriaId, entry.Description, newValues.Description, entry.IsSeparator);
            if (descriptionError != null)
                yield return descriptionError;

            foreach (var section in _sectionMaintenances)
            {
                var errors = section.Validate(entry, newValues).ToArray();
                foreach (var error in errors)
                    yield return error;
            }
        }

        public void UpdateEntryDetail(DataEntryTask entryToUpdate, WorkflowEntryControlSaveModel newValues)
        {
            var descriptionModified = Helper.AreDescriptionsDifferent(entryToUpdate.Description, newValues.Description, !entryToUpdate.IsSeparator);

            UpdateEntryDetail(entryToUpdate, newValues, new EntryControlFieldsToUpdate(entryToUpdate, newValues));

            if (descriptionModified && !newValues.ResetInheritance)
            {
                entryToUpdate.RemoveInheritance();
            }

            _dbContext.SaveChanges();

            UpdateDisplayOrder(entryToUpdate, new EntryControlRecordMovements(entryToUpdate, newValues), newValues.ApplyToDescendants);

            _dbContext.SaveChanges();
        }

        void UpdateDisplayOrder(DataEntryTask entryToUpdate, EntryControlRecordMovements movements, bool applyToDescendents)
        {
            var reorderSouce = _mapper.Map<EntryReorderSouce>(entryToUpdate);

            foreach (var section in _reorderableSections)
            {
                section.UpdateDisplayOrder(entryToUpdate, movements);

                if(applyToDescendents)
                    UpdateDescendantDisplayOrder(reorderSouce, entryToUpdate, movements, section);
            }
        }

        void UpdateDescendantDisplayOrder(EntryReorderSouce source, DataEntryTask current, EntryControlRecordMovements movements, IReorderableSection section)
        {
            var children = _inheritance.GetChildren(current.CriteriaId);

            foreach (var child in children)
            {
                var childEntries = child.DataEntryTasks.AsQueryable()
                                        .Inherited()
                                        .Where(_ => _.ParentCriteriaId == current.CriteriaId && _.ParentEntryId == current.Id)
                                        .ToArray();

                if (childEntries.Length != 1)
                    continue;

                var childEntry = childEntries.Single();

                if (!section.PropagateDisplayOrder(source, childEntry, movements)) continue;

                UpdateDescendantDisplayOrder(source, childEntry, movements, section);
            }
        }

        void UpdateEntryDetail(DataEntryTask entryToUpdate, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var children = _inheritance.GetChildren(entryToUpdate.CriteriaId);

            foreach (var child in children)
            {
                var childEntries = child.DataEntryTasks.AsQueryable()
                                        .Inherited()
                                        .Where(_=>_.ParentCriteriaId == entryToUpdate.CriteriaId && _.ParentEntryId == entryToUpdate.Id)
                                        .ToArray();

                if (childEntries.Length != 1)
                    continue;

                var childEntry = childEntries.Single();
                if(childEntry.IsSeparator != entryToUpdate.IsSeparator)
                    continue;

                if (newValues.ApplyToDescendants && _descriptionValidator.IsDescriptionUnique(childEntry.CriteriaId, childEntry.Description, newValues.Description, childEntry.IsSeparator))
                {
                    var childFieldsToUpdate = (EntryControlFieldsToUpdate) fieldsToUpdate.Clone();
                    SetFieldsToUpdate(childEntry, entryToUpdate, newValues, childFieldsToUpdate);

                    UpdateEntryDetail(childEntry, newValues, childFieldsToUpdate);
                }
                else
                {
                    if (Helper.AreDescriptionsDifferent(entryToUpdate.Description, newValues.Description, !childEntry.IsSeparator))
                    {
                        childEntry.RemoveInheritance();
                    }
                    else
                    {
                        foreach (var sectionMaintenance in _sectionMaintenances)
                        {
                            sectionMaintenance.RemoveInheritance(childEntry, fieldsToUpdate);
                        }
                    }
                }
            }

            SetUpdatedValuesForEntry(entryToUpdate, newValues, fieldsToUpdate);
        }

        void SetFieldsToUpdate(DataEntryTask current, DataEntryTask parent, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            foreach (var propToUpdate in EntryControlFieldsToUpdate.All)
            {
                if (!(bool) propToUpdate.GetValue(fieldsToUpdate)) continue;
                if (propToUpdate.Name == "Description") continue;

                var entryProp = typeof (DataEntryTask).GetProperty(propToUpdate.Name);

                if ((dynamic) entryProp.GetValue(current) != (dynamic) entryProp.GetValue(parent))
                    propToUpdate.SetValue(fieldsToUpdate, false);
            }

            foreach (var sectionMaintenance in _sectionMaintenances)
            {
                sectionMaintenance.SetDeltaForUpdate(current, newValues, fieldsToUpdate);
            }
        }

        void SetUpdatedValuesForEntry(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            SetIndividualFields(entry, newValues, fieldsToUpdate);
            foreach (var sectionMaintenance in _sectionMaintenances)
            {
                sectionMaintenance.ApplyChanges(entry, newValues, fieldsToUpdate);
            }
        }

        void SetIndividualFields(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var newEntry = _mapper.Map<DataEntryTask>(newValues);
            foreach (var propToUpdate in EntryControlFieldsToUpdate.All)
            {
                if (!(bool) propToUpdate.GetValue(fieldsToUpdate))
                    continue;

                var entryProp = typeof (DataEntryTask).GetProperty(propToUpdate.Name);

                var newValue = entryProp.GetValue(newEntry);
                entryProp.SetValue(entry, newValue);
            }
        }
    }
}