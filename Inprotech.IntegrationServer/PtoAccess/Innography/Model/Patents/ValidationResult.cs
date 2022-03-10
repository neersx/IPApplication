using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents
{
    public class ValidationResult
    {
        [JsonProperty(PropertyName = "ipid")]
        public string InnographyId { get; set; }

        [JsonProperty(PropertyName = "client_index")]
        public string ClientIndex { get; set; }

        [JsonProperty(PropertyName = "application_number")]
        public MatchingFieldData ApplicationNumber { get; set; }

        [JsonProperty(PropertyName = "application_date")]
        public MatchingFieldData ApplicationDate { get; set; }

        [JsonProperty(PropertyName = "publication_number")]
        public MatchingFieldData PublicationNumber { get; set; }

        [JsonProperty(PropertyName = "publication_date")]
        public MatchingFieldData PublicationDate { get; set; }

        [JsonProperty(PropertyName = "grant_number")]
        public MatchingFieldData GrantNumber { get; set; }

        [JsonProperty(PropertyName = "grant_date")]
        public MatchingFieldData GrantDate { get; set; }

        [JsonProperty(PropertyName = "type_code")]
        public MatchingFieldData TypeCode { get; set; }

        [JsonProperty(PropertyName = "country_code")]
        public MatchingFieldData CountryCode { get; set; }

        [JsonProperty(PropertyName = "country_name")]
        public MatchingFieldData CountryName { get; set; }

        [JsonProperty(PropertyName = "title")]
        public MatchingFieldData Title { get; set; }

        [JsonProperty(PropertyName = "inventors")]
        public MatchingFieldData Inventors { get; set; }

        [JsonProperty(PropertyName = "grant_publication_date")]
        public MatchingFieldData GrantPublicationDate { get; set; }

        [JsonProperty(PropertyName = "pct_number")]
        public MatchingFieldData PctNumber { get; set; }
        
        [JsonProperty(PropertyName = "pct_date")]
        public MatchingFieldData PctDate { get; set; }

        [JsonProperty(PropertyName = "pct_country")]
        public MatchingFieldData PctCountry { get; set; }

        [JsonProperty(PropertyName = "priority_number")]
        public MatchingFieldData PriorityNumber { get; set; }
        
        [JsonProperty(PropertyName = "priority_date")]
        public MatchingFieldData PriorityDate { get; set; }

        [JsonProperty(PropertyName = "priority_country")]
        public MatchingFieldData PriorityCountry { get; set; }
    }
}