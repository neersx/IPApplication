using System.Collections.Generic;

namespace Inprotech.Web.PriorArt
{
    public class PriorArtSearchViewModel
    {
        public bool HasUpdatePermission { get; set; }
        public bool HasDeletePermission { get; set; }
        public bool CanViewAttachment { get; set; }
        public bool CanMaintainAttachment { get; set; }
        public SourceDocumentModel SourceDocumentData { get; set; }
        public int? CaseKey { get; set; }
        public IEnumerable<TableCodeItem> PriorArtSourceTableCodes { get; set; }
        public string CaseIrn { get; set; }
    }
    public class TableCodeItem
    {
        public int Id { get; set; }
        public string Name { get; set; }
    }
}
