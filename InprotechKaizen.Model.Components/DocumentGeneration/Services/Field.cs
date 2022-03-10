using InprotechKaizen.Model.Components.DocumentGeneration.Processor;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Services
{
    public class Field
    {
        public string FieldName { get; set; }
        public FieldType? FieldType { get; set; }
        public DestinationType DestinationType { get; set; }
        public RowsReturnedMode RowsReturnedMode { get; set; }
    }
}