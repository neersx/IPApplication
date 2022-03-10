using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Configuration.TableMaintenance
{
    public class TableMaintenanceValidationResult
    {
        public string Status { get; set; }

        public bool IsValid { get; set; }

        public List<TableMaintenanceValidationMessage> ValidationMessages { get; set; } 
    }
}
