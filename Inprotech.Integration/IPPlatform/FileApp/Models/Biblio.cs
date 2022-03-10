using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.IPPlatform.FileApp.Models
{
    public class Biblio
    {
        [JsonProperty("publicationNo")]
        public string PublicationNumber { get; set; }

        [JsonProperty("publicationDate")]
        public string PublicationDate { get; set; }

        [JsonProperty("intlApplicationNo")]
        public string ApplicationNumber { get; set; }

        [JsonProperty("intlFilingDate")]
        public string ApplicationDate { get; set; }

        [JsonProperty("applicationTitle")]
        public string Title { get; set; }

        [JsonProperty("priorityNo")]
        public string PriorityNumber { get; set; }

        [JsonProperty("priorityDate")]
        public string PriorityDate { get; set; }

        [JsonProperty("priorityCountry")]
        public string PriorityCountry { get; set; }

        [JsonProperty("filingLanguage")]
        public string FilingLanguage { get; set; }

        [JsonProperty("publicationLanguage")]
        public string PublicationLanguage { get; set; }

        [JsonProperty("descriptionPageCount")]
        public int? DecriptionPageCount { get; set; }

        [JsonProperty("claimsCount")]
        public int? ClaimsCount { get; set; }

        [JsonProperty("claimsPageCount")]
        public int? ClaimsPageCount { get; set; }

        [JsonProperty("drawingsCount")]
        public int? DrawingsCount { get; set; }

        [JsonProperty("pageCount")]
        public int? PageCount { get; set; }

        [JsonProperty("claimsPriority")]
        public bool? ClaimsPriority { get; set; }

        [JsonProperty("mark")]
        public string Mark { get; set; }
    
        [JsonProperty("classes")]
        public IList<BibloClasses> Classes { get; set; }
    }
    
    public static class BiblioExt
    {
        public static bool IsEmpty(this Biblio biblio)
        {
            return string.IsNullOrWhiteSpace(biblio.ApplicationNumber) &&
                   string.IsNullOrWhiteSpace(biblio.ApplicationDate) &&
                   string.IsNullOrWhiteSpace(biblio.PriorityNumber) &&
                   string.IsNullOrWhiteSpace(biblio.PriorityDate) &&
                   string.IsNullOrWhiteSpace(biblio.PriorityCountry);
        }
    }
}