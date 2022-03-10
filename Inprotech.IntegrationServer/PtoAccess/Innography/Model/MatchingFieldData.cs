using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model
{
    public class MatchingFieldData
    {
        [JsonProperty(PropertyName = "message")]
        public string Message { get; set; }

        [JsonProperty(PropertyName = "status_code")]
        public string StatusCode { get; set; }

        [JsonProperty(PropertyName = "input")]
        public string Input { get; set; }

        [JsonProperty(PropertyName = "public_data")]
        public string PublicData { get; set; }
    }
}