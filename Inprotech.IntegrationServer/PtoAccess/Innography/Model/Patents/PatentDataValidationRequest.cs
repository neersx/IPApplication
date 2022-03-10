using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents
{
    public class PatentDataValidationRequest : PatentData
    {
        [JsonProperty(PropertyName = "ipid")]
        public string IpId { get; set; }

        [JsonProperty(PropertyName = "client_index")]
        public string ClientIndex { get; set; }

        [JsonProperty(PropertyName = "priority_number")]
        public string PriorityNumber { get; set; }
        
        [JsonProperty(PropertyName = "priority_date")]
        public string PriorityDate { get; set; }

        [JsonProperty(PropertyName = "priority_country")]
        public string PriorityCountry { get; set; }
    }
}