using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks
{
    public class TrademarkData
    {
        [JsonProperty(PropertyName = "mark")]
        public string Mark { get; set; }

        [JsonProperty(PropertyName = "status")]
        public string Status { get; set; }

        [JsonProperty(PropertyName = "owner")]
        public string Owner { get; set; }
        
        [JsonProperty(PropertyName = "registration_number")]
        public string RegistrationNumber { get; set; }

        [JsonProperty(PropertyName = "registration_date")]
        public string RegistrationDate { get; set; }

        [JsonProperty(PropertyName = "application_number")]
        public string ApplicationNumber { get; set; }

        [JsonProperty(PropertyName = "application_date")]
        public string ApplicationDate { get; set; }

        [JsonProperty(PropertyName = "publication_number")]
        public string PublicationNumber { get; set; }

        [JsonProperty(PropertyName = "publication_date")]
        public string PublicationDate { get; set; }

        [JsonProperty(PropertyName = "expiration_date")]
        public string ExpirationDate { get; set; }

        [JsonProperty(PropertyName = "termination_date")]
        public string TerminationDate { get; set; }
        
        [JsonProperty(PropertyName = "priority_number")]
        public string PriorityNumber { get; set; }

        [JsonProperty(PropertyName = "priority_date")]
        public string PriorityDate { get; set; }

        [JsonProperty(PropertyName = "priority_country")]
        public string PriorityCountry { get; set; }

        [JsonProperty(PropertyName = "country_code")]
        public string CountryCode { get; set; }

        [JsonProperty(PropertyName = "mark_type")]
        public string MarkType { get; set; }

        [JsonProperty(PropertyName = "goods_services_nice")]
        public GoodsServicesNice[] GoodsServicesNice { get; set; }
    }

    public class GoodsServicesNice
    {
        [JsonProperty("class_code")]
        public string ClassCode { get; set; }

        [JsonProperty("goods_description")]
        public string GoodsDescription { get; set; }
    }
}
