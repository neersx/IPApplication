using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.Configuration.TableMaintenance;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Properties;

namespace InprotechKaizen.Model.Components.Names.Validation
{
    public interface INameRelationValidator : ITableMaintenanceValidator<string> {}

    public class NameRelationValidator : INameRelationValidator
    {
        readonly IDbContext _dbContext;
        
        public NameRelationValidator(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public TableMaintenanceValidationResult ValidateOnDelete(string id)
        {
            return TableMaintenanceValidationResultHelper.SuccessResult();
        }

        public TableMaintenanceValidationResult ValidateOnPost(object entity)
        {
            if (entity == null) throw new ArgumentNullException("entity");
            
            var nameRelation = entity as NameRelation;
            if(nameRelation==null) throw new InvalidCastException("invalid entity");

            var errorMessages = Validate(nameRelation);
            if (errorMessages.Count > 0)
                return TableMaintenanceValidationResultHelper.FailureResult(errorMessages);

            if (_dbContext.Set<NameRelation>().Any
                (ent => ent.Id == nameRelation.Id))
                return TableMaintenanceValidationResultHelper.FailureResult(new TableMaintenanceValidationMessage("duplicateNameRelationDescription", new []{"id"}));
            
            return TableMaintenanceValidationResultHelper.SuccessResult();
        }

        static List<TableMaintenanceValidationMessage> Validate(NameRelation nameRelation)
        {
            var errorMessages=new List<TableMaintenanceValidationMessage>();

            if (string.IsNullOrWhiteSpace(nameRelation.RelationshipCode))
                errorMessages.Add(new TableMaintenanceValidationMessage(ConfigurationResources.NameRelationCodeRequired, new []{"id"}));

            if (string.IsNullOrWhiteSpace(nameRelation.RelationDescription))
                errorMessages.Add(new TableMaintenanceValidationMessage(ConfigurationResources.NameRelationDescriptionRequired, new []{"relationshipDescription"}));

            if (string.IsNullOrWhiteSpace(nameRelation.ReverseDescription))
                errorMessages.Add(new TableMaintenanceValidationMessage(ConfigurationResources.NameRelationReverseRelationRequired, new []{"reverseDescription"}));

            if (nameRelation.UsedByNameType <= 0)
                errorMessages.Add(new TableMaintenanceValidationMessage(ConfigurationResources.NameRelationAtleastOneOptionRequired, new []{"isEmployee, isIndividual, isOrganisation, isCrmOnly"}));

            return errorMessages;
        }

        public TableMaintenanceValidationResult ValidateOnPut(object entity, object modifiedEntity)
        {
            if (entity == null) throw new ArgumentNullException("entity");
            if (modifiedEntity == null) throw new ArgumentNullException("modifiedEntity");

            var nameRelation = entity as NameRelation;
            var modifiedNameRelation = modifiedEntity as NameRelation;

            var errorMessages = Validate(modifiedNameRelation);
            if (errorMessages.Count > 0)
                return TableMaintenanceValidationResultHelper.FailureResult(errorMessages);

            if (nameRelation != null && (modifiedNameRelation != null &&
                                    _dbContext.Set<NameRelation>().Any(ent => ent.Id == modifiedNameRelation.Id)))
                return TableMaintenanceValidationResultHelper.SuccessResult();

            return TableMaintenanceValidationResultHelper.FailureResult(new TableMaintenanceValidationMessage("nameRelationNotFound", new []{"id"}));
        }
    }
}