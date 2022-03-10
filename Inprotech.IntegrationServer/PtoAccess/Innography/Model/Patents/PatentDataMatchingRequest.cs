using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents
{
    public class PatentDataMatchingRequest : PatentData
    {
        [JsonProperty(PropertyName = "client_index")]
        public string ClientIndex { get; set; }

        [JsonProperty(PropertyName = "parent_number")]
        public string ParentNumber { get; set; }
        
        [JsonProperty(PropertyName = "parent_date")]
        public string ParentDate { get; set; }

        [JsonProperty(PropertyName = "parent_country")]
        public string ParentCountry { get; set; }
    }
}