using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.Configuration.TableMaintenance;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Names.Validation
{
    public interface IAliasTypeValidator : ITableMaintenanceValidator<string>
    {
    }

    public class AliasTypeValidator : IAliasTypeValidator
    {
        readonly IDbContext _dbContext;

        public AliasTypeValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public TableMaintenanceValidationResult ValidateOnDelete(string id)
        {
            var validationResult = new TableMaintenanceValidationResult
            {
                IsValid = true,
                Status = "success"
            };

            var validationMessages = new List<TableMaintenanceValidationMessage>();

            var nameAliasExists = _dbContext.Set<NameAlias>().Any(na => na.AliasType.Code == id);

            if (nameAliasExists)
            {
                validationMessages.Add(new TableMaintenanceValidationMessage("entityAlreadyInUse"));
            }

            return !validationMessages.Any() ?
                validationResult
                : TableMaintenanceValidationResultHelper.FailureResult(validationMessages);
        }
        
        public TableMaintenanceValidationResult ValidateOnPost(object aliasType)
        {
            var duplicateAliasDescriptionExists = _dbContext.Set<NameAliasType>().Any
                        (ent => ent.Description == ((NameAliasType)aliasType).Description);

            var duplicateAliasTypeExists = _dbContext.Set<NameAliasType>().Any
                        (ent => ent.Id == ((NameAliasType)aliasType).Id);

            var messages = new List<TableMaintenanceValidationMessage>();

            if (duplicateAliasTypeExists)
                messages.Add(new TableMaintenanceValidationMessage("duplicateNameAliasType", new[] { "id" }));

            if (duplicateAliasDescriptionExists)
                messages.Add(new TableMaintenanceValidationMessage("duplicateNameAliasDescription", new[] { "description" }));

            return messages.Any() ? TableMaintenanceValidationResultHelper.FailureResult(messages) : TableMaintenanceValidationResultHelper.SuccessResult();
        }

        public TableMaintenanceValidationResult ValidateOnPut(object aliasType, object modifiedAliasType)
        {
            var nameAliasType = aliasType as NameAliasType;
            var modifiedNameAliasType = modifiedAliasType as NameAliasType;

            if (nameAliasType != null &&
                (modifiedNameAliasType != null && (nameAliasType.Description != modifiedNameAliasType.Description
                                                   && _dbContext.Set<NameAliasType>().Any
                                                       (ent => ent.Description == modifiedNameAliasType.Description)
                    )))
            {
                var messages = new List<TableMaintenanceValidationMessage>();
                messages.Add(
                    new TableMaintenanceValidationMessage(
                        "duplicateNameAliasDescription", new[] {"description"}));
                return TableMaintenanceValidationResultHelper.FailureResult(messages); 
            } 

            return TableMaintenanceValidationResultHelper.SuccessResult();
        }
        
    }
}
