using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Configuration.TableMaintenance
{
    public static class TableMaintenanceValidationResultHelper
    {
        public static TableMaintenanceValidationResult SuccessResult()
        {
            return new TableMaintenanceValidationResult
                   {
                       IsValid = true,
                       Status = "success"
                   };
        }

        public static TableMaintenanceValidationResult FailureResult(List<TableMaintenanceValidationMessage> validationMessages)
        {
            return new TableMaintenanceValidationResult
                   {
                       IsValid = false,
                       Status = "failed",
                       ValidationMessages = validationMessages
                   };
        }

        public static TableMaintenanceValidationResult FailureResult(TableMaintenanceValidationMessage validationMessage)
        {
            var messages = new List<TableMaintenanceValidationMessage> {validationMessage};
            return FailureResult(messages);
        }
    }
}