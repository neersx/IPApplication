
namespace InprotechKaizen.Model.Components.Configuration.TableMaintenance
{
    public class ColumnDefinition
    {
        public ColumnDefinition(string columnName, string title, string dataType, bool isHidden, bool isMandatory = false, string width = null)
        {
            ColumnName = columnName;
            Title = title;
            DataType = dataType;
            Hidden = isHidden;
            Width = width;
            IsMandatory = isMandatory;
        }

        public string ColumnName { get; set; }

        public string Title { get; set; }

        public string DataType { get; set; }

        public bool Hidden { get; set; }

        public string Width { get; set; }

        public bool IsMandatory { get; set; }
    }
}
