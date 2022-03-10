using System;
using System.Diagnostics.CodeAnalysis;
using Inprotech.Infrastructure.Web;

namespace InprotechKaizen.Model.Components.Cases.PriorArt
{
    public class SearchResult
    {
        public SearchResult()
        {
            Matches = new PagedResults<Match>(new Match[0], 0);
        }

        public string Source { get; set; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public PagedResults<Match> Matches { get; set; }

        public bool Errors { get; set; }

        public string Message { get; set; }

        public static SearchResult ForErrors(string source, string message)
        {
            return new SearchResult
            {
                Errors = true,
                Source = source,
                Message = message
            };
        }
    }

    public class SearchResultOptions
    {
        public SearchResultOptions()
        {
            ReferenceHandling = new SearchResultReferenceHandling();
        }

        public SearchResultReferenceHandling ReferenceHandling { get; set; }
    }

    public class SearchResultReferenceHandling
    {
        public bool IsIpPlatformSession { get; set; }
    }

    public class Match
    {
        public string Id { get; set; }

        public string Reference { get; set; }

        public string SubClasses { get; set; }

        public string Classes { get; set; }

        public string Citation { get; set; }

        public string Title { get; set; }

        public string Name { get; set; }

        public string Kind { get; set; }

        public string Abstract { get; set; }

        public DateTime? ApplicationDate { get; set; }

        public DateTime? PublishedDate { get; set; }

        public DateTime? GrantedDate { get; set; }

        public DateTime? PriorityDate { get; set; }

        public DateTime? PtoCitedDate { get; set; }

        public Uri ReferenceLink { get; set; }

        public bool IsComplete { get; set; }

        public string CountryName { get; set; }

        public string CountryCode { get; set; }

        public string Origin { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1721:PropertyNamesShouldNotMatchGetMethods")]
        public string Type => GetType().Name;

        public string OfficialNumber { get; set; }

        public string CaseStatus { get; set; }

        public string Comments { get; set; }

        public int? Translation { get; set; }

        public string RefDocumentParts { get; set; }

        public string Description { get; set; }
        public bool IsIpoIssued { get; set; }
    }
}