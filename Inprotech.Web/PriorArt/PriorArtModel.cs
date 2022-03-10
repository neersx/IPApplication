using System;

namespace Inprotech.Web.PriorArt
{
    public class PriorArtModel
    {
        public string OfficialNumber { get; set; }
        public string CountryCode { get; set; }
        public string Comments { get; set; }
        public string Description { get; set; }
        public string Kind { get; set; }
        public string Title { get; set; }
        public string Abstract { get; set; }
        public string Citation { get; set; }
        public string Name { get; set; }
        public string RefDocumentParts { get; set; }
        public int? Translation { get; set; }
        public DateTime? PublishedDate { get; set; }
        public DateTime? PriorityDate { get; set; }
        public DateTime? GrantedDate { get; set; }
        public DateTime? PtoCitedDate { get; set; }
        public DateTime? ApplicationFiledDate { get; set; }
        public int? SourceId { get; set; }
        public string CorrelationId { get; set; }
        public string ImportedFrom { get; set; }
        public int? CaseKey { get; set; }
        public bool IsLiterature { get; set; }
        public string Publisher { get; set; }
        public string City { get; set; }
    }
}