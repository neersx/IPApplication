using InprotechKaizen.Model.Components.Cases.PriorArt;

namespace Inprotech.Web.PriorArt
{
    public class ImportEvidenceModel
    {
        public Match Evidence { get; set; }

        public string Country { get; set; }

        public string OfficialNumber { get; set; }

        public int? SourceDocumentId { get; set; }

        public string Source { get; set; }

        public int? CaseKey { get; set; }
    }
}