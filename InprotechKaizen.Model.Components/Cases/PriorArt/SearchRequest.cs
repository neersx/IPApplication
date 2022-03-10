using Inprotech.Infrastructure.Web;

namespace InprotechKaizen.Model.Components.Cases.PriorArt
{
    public class SearchRequest
    {
        public int? SourceDocumentId { get; set; }
        public int? CaseKey { get; set; }
        public string OfficialNumber { get; set; }
        public string Country { get; set; }
        public string Kind { get; set; }
        public int? SourceId { get; set; }
        public string Description { get; set; }
        public string Publication { get; set; }
        public string Comments { get; set; }
        public int SourceType { get; set; }
        public bool? IsSourceDocument { get; set; }
        public string Inventor { get; set; }
        public string Title { get; set; }
        public string Publisher { get; set; }
        public CommonQueryParameters QueryParameters { get; set; }
        public int IpoSearchType { get; set; }
        public IpoSearchRequest[] MultipleIpoSearch { get; set; }
    }

    public class IpoSearchRequest
    {
        public string Country { get; set; }
        public string OfficialNumber { get; set; }
        public string Kind { get; set; }
    }

    public class PriorArtTypes
    {
        public const int Ipo = 1;
        public const int Literature = 2;
        public const int Source = 3;
        public const int NewSource = 4;
    }

    public class IpoSearchType
    {
        public const int Single = 1;
        public const int Multiple = 2;
    }
}
