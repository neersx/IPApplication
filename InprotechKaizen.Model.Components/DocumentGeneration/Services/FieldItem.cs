namespace InprotechKaizen.Model.Components.DocumentGeneration.Services
{
    public class FieldItem
    {
        public int DocumentId { get; set; }
        public string FieldName { get; set; }
        public string FieldDescription { get; set; }
        public FieldType? FieldType { get; set; }
        public int? ItemId { get; set; }
        public string ItemName { get; set; }
        public string ItemDescription { get; set; }
        public string ItemParameter { get; set; }
        public string ResultSeparator { get; set; }
    }
}