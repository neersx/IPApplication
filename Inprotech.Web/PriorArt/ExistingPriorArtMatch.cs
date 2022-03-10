using System;
using InprotechKaizen.Model.Components.Cases.PriorArt;

namespace Inprotech.Web.PriorArt
{
    public class ExistingPriorArtMatch : Match
    {
        public int? SourceDocumentId { get; set; }

        public string PriorArtStatus { get; set; }

        public bool IsCited { get; set; }

        public DateTime? PriorityDate { get; set; }

        public DateTime? PtoCitedDate { get; set; }

        public string Description { get; set; }

        public string Publication { get; set; }

        public string Comments { get; set; }

        public string RefDocumentParts { get; set; }

        public int? Translation { get; set; }

        public DateTime? ReportReceived { get; set; }

        public DateTime? ReportIssued { get; set; }

        public string IssuingJurisdiction { get; set; }

        public string SourceType { get; set; }
        public DateTime? LastModifiedDate { get; set; }
        public string Publisher { get; set; }
        public DateTime? Published { get; set; }
        public string City { get; set; }
        public SourceJurisdiction Country { get; set; }
    }
}