using System;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents
{
    public class PatentData
    {
        [JsonProperty(PropertyName = "application_number")]
        public string ApplicationNumber { get; set; }

        [JsonProperty(PropertyName = "application_date")]
        public string ApplicationDate { get; set; }

        [JsonProperty(PropertyName = "publication_number")]
        public string PublicationNumber { get; set; }

        [JsonProperty(PropertyName = "publication_date")]
        public string PublicationDate { get; set; }

        [JsonProperty(PropertyName = "grant_number")]
        public string GrantNumber { get; set; }

        [JsonProperty(PropertyName = "grant_date")]
        public string GrantDate { get; set; }

        [JsonProperty(PropertyName = "type_code")]
        public string TypeCode { get; set; }

        [JsonProperty(PropertyName = "country_code")]
        public string CountryCode { get; set; }

        [JsonProperty(PropertyName = "country_name")]
        public string CountryName { get; set; }

        [JsonProperty(PropertyName = "title")]
        public string Title { get; set; }
        
        [JsonProperty(PropertyName = "inventors")]
        public string Inventors { get; set; }

        [JsonProperty(PropertyName = "grant_publication_date")]
        public string GrantPublicationDate { get; set; }

        [JsonProperty(PropertyName = "pct_number")]
        public string PctNumber { get; set; }
        
        [JsonProperty(PropertyName = "pct_date")]
        public string PctDate { get; set; }

        [JsonProperty(PropertyName = "pct_country")]
        public string PctCountry { get; set; }
    }

    public static class PatentDataExtension
    {
        public static DateTime? ToDateTime(this string dateTime)
        {
            if (string.IsNullOrWhiteSpace(dateTime))
                return null;

            return DateTime.Parse(dateTime);
        }
    }
}