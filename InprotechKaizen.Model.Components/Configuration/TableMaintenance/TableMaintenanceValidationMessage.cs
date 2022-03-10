using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Components.Configuration.TableMaintenance
{
    public class TableMaintenanceValidationMessage
    {
        public TableMaintenanceValidationMessage(string message, string[] columns = null)
        {
            ValidationMessage = message;
            ColumnNames = columns;
        }

        public string ValidationMessage { get; set; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public string[] ColumnNames { get; set; }
    }
}