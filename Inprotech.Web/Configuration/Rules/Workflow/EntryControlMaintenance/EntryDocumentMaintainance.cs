using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

#pragma warning disable 618

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public class EntryDocumentMaintainance : ISectionMaintenance
    {
        readonly IDbContext _dbContext;

        public EntryDocumentMaintainance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public void ApplyChanges(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            ApplyDelete(entry, newValues, fieldsToUpdate);

            ApplyUpdates(entry, newValues, fieldsToUpdate);

            ApplyAdditions(entry, newValues, fieldsToUpdate);
        }

        public void RemoveInheritance(DataEntryTask entry, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            foreach (var removeInheritanceFor in fieldsToUpdate.DocumentsDelta.Updated.Union(fieldsToUpdate.DocumentsDelta.Deleted))
            {
                var documentToUpdate = entry.DocumentRequirements.Where(_ => removeInheritanceFor == _.DocumentId).SingleOrDefault(_ => _.IsInherited);
                if (documentToUpdate == null)
                    continue;

                documentToUpdate.IsInherited = false;
            }
        }

        public void SetDeltaForUpdate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var currentDocumentIds = entry.DocumentRequirements.Select(_ => _.DocumentId).ToArray();
            var currentInheritedDocumentIds = entry.DocumentRequirements.Where(_ => _.IsInherited).Select(_ => _.DocumentId).ToArray();

            fieldsToUpdate.DocumentsDelta.Added = fieldsToUpdate.DocumentsDelta.Added.Except(currentDocumentIds).ToArray();
            fieldsToUpdate.DocumentsDelta.Deleted = fieldsToUpdate.DocumentsDelta.Deleted.Intersect(currentInheritedDocumentIds).ToArray();

            var updatedDocumentAlreadyPresent = newValues.DocumentsDelta.Updated
                                                         .Where(_ => _.PreviousDocumentId.HasValue && IsDocumentModified(_))
                                                         .Where(_ => currentDocumentIds.Contains(_.DocumentId))
                                                         .Select(_ => _.PreviousDocumentId)
                                                         .Cast<short>()
                                                         .ToArray();

            var updatesApplicable = fieldsToUpdate.DocumentsDelta.Updated
                                                  .Intersect(currentInheritedDocumentIds)
                                                  .Except(updatedDocumentAlreadyPresent)
                                                  .ToArray();

            fieldsToUpdate.DocumentsRemoveInheritanceFor = fieldsToUpdate.DocumentsDelta.Updated.Except(updatesApplicable).ToArray();
            fieldsToUpdate.DocumentsDelta.Updated = updatesApplicable;
        }

        public IEnumerable<ValidationError> Validate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues)
        {
            var duplicateEvents = DuplicateDocumentsinAddedDocumentRequirement(entry, newValues.DocumentsDelta.Added, newValues.DocumentsDelta.Deleted)
                .Union(DuplicateDocumentsinAddedDocumentRequirement(entry, newValues.DocumentsDelta.Updated.Where(_ => _.DocumentId != _.PreviousDocumentId), newValues.DocumentsDelta.Deleted)).ToArray();
            if (!duplicateEvents.Any())
                yield break;

            foreach (var duplicateEvent in duplicateEvents)
                yield return ValidationErrors.NotUnique("documents", "entryDocuments", duplicateEvent);
        }

        public void Reset(DataEntryTask entryToReset, DataEntryTask parentEntry, WorkflowEntryControlSaveModel newValues)
        {
            foreach (var d in parentEntry.DocumentRequirements)
            {
                var saveModel = new EntryDocumentDelta(d.DocumentId, d.IsMandatory);
                if (entryToReset.DocumentRequirements.Any(_ => _.DocumentId == d.DocumentId))
                {
                    saveModel.PreviousDocumentId = saveModel.DocumentId;
                    newValues.DocumentsDelta.Updated.Add(saveModel);
                }
                else
                {
                    newValues.DocumentsDelta.Added.Add(saveModel);
                }
            }

            var keep = newValues.DocumentsDelta.Updated.Select(_ => _.DocumentId);
            var deletes = entryToReset.DocumentRequirements.Where(_ => !keep.Contains(_.DocumentId))
                .Select(_ => new EntryDocumentDelta(_.DocumentId, _.IsMandatory));
            newValues.DocumentsDelta.Deleted.AddRange(deletes);
        }

        void ApplyDelete(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var allDeletedDocuments = newValues.DocumentsDelta.Deleted.Where(_ => fieldsToUpdate.DocumentsDelta.Deleted.Contains(_.DocumentId));
            foreach (var deleted in allDeletedDocuments)
            {
                var document = entry.DocumentRequirements.FirstOrDefault(_ => _.DocumentId == deleted.DocumentId);
                if (document == null) continue;

                entry.DocumentRequirements.Remove(document);
            }
        }

        void ApplyUpdates(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var isUpdatingChildCriteria = Helper.IsUpdateForChildCriteria(entry, newValues);
            var documentsToBeAdded = new List<DocumentRequirement>();
            var updatedDocuments = newValues.DocumentsDelta.Updated.Where(_ => fieldsToUpdate.DocumentsDelta.Updated.Contains(_.PreviousDocumentId.Value)).ToArray();
            var dbDocuments = GetDocuments(updatedDocuments.Select(s => s.DocumentId));

            foreach (var updatedDocument in updatedDocuments)
            {
                var documentToUpdateQuery = entry.DocumentRequirements.Where(_ => updatedDocument.PreviousDocumentId == _.DocumentId);

                var documentToUpdate = (isUpdatingChildCriteria ? documentToUpdateQuery.Where(_ => _.IsInherited) : documentToUpdateQuery).SingleOrDefault();

                if (documentToUpdate == null)
                    continue;

                //New entity created, since its primary key change and EF does not like updating primary key directly
                var modifiedEntity = IsDocumentModified(updatedDocument) ? GetNewEntity(entry, documentToUpdate, dbDocuments.Single(_ => _.Id == updatedDocument.DocumentId)) : documentToUpdate;
                
                modifiedEntity.InternalMandatoryFlag = updatedDocument.MustProduce ? 1 : 0;

                if (IsDocumentModified(updatedDocument))
                    documentsToBeAdded.Add(modifiedEntity);

                if (!isUpdatingChildCriteria)
                    modifiedEntity.IsInherited = newValues.ResetInheritance;
            }

            if (documentsToBeAdded.Count > 0)
                entry.DocumentRequirements.AddRange(documentsToBeAdded.ToArray());

            foreach (var documentId in fieldsToUpdate.DocumentsRemoveInheritanceFor)
            {
                var documentToUpdate = entry.DocumentRequirements.SingleOrDefault(_ => _.DocumentId == documentId && _.IsInherited);
                if (documentToUpdate != null)
                    documentToUpdate.IsInherited = false;
            }
        }

        void ApplyAdditions(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var isUpdatingChildCriteria = Helper.IsUpdateForChildCriteria(entry, newValues);
            var newDocuments = newValues.DocumentsDelta.Added.Where(_ => fieldsToUpdate.DocumentsDelta.Added.Contains(_.DocumentId)).ToArray();
            if (newDocuments.Any())
            {
                var dbDocuments = GetDocuments(newDocuments.Select(s => s.DocumentId));

                foreach (var newDocument in newDocuments)
                {
                    if (entry.DocumentRequirements.Any(_ => newDocument.DocumentId == _.DocumentId))
                        continue;

                    var newDocumentReq = new DocumentRequirement(entry.Criteria, entry, dbDocuments.Single(_ => _.Id == newDocument.DocumentId))
                    {
                        InternalMandatoryFlag = newDocument.MustProduce ? 1 : 0,
                        IsInherited = isUpdatingChildCriteria || newValues.ResetInheritance
                    };
                    entry.DocumentRequirements.Add(newDocumentReq);
                }
            }
        }

        bool IsDocumentModified(EntryDocumentDelta updatedEntryDocument)
        {
            return updatedEntryDocument.DocumentId != updatedEntryDocument.PreviousDocumentId;
        }

        DocumentRequirement GetNewEntity(DataEntryTask entry, DocumentRequirement documentToUpdate, Document dbDocument)
        {
            entry.DocumentRequirements.Remove(documentToUpdate);
            var newEntity = new DocumentRequirement(entry.Criteria, entry, dbDocument);
            newEntity.Inherited = documentToUpdate.Inherited;
            newEntity.InternalMandatoryFlag = documentToUpdate.InternalMandatoryFlag;
            newEntity.DeliveryMethodFlag = documentToUpdate.DeliveryMethodFlag;

            return newEntity;
        }

        Document[] GetDocuments(IEnumerable<short> docIds)
        {
            return _dbContext.Set<Document>().Where(_ => docIds.Contains(_.Id)).ToArray();
        }

        IEnumerable<int> DuplicateDocumentsinAddedDocumentRequirement(DataEntryTask entryToUpdate, IEnumerable<EntryDocumentDelta> newDocuments, IEnumerable<EntryDocumentDelta> deletedDocuments)
        {
            var newEntryDocumentIds = newDocuments.Select(_ => _.DocumentId).Except(deletedDocuments.Select(_ => _.DocumentId));
            foreach (var newDocumentId in newEntryDocumentIds)
                if (entryToUpdate.DocumentRequirements.Any(_ => _.DocumentId == newDocumentId))
                    yield return newDocumentId;
        }
    }
}