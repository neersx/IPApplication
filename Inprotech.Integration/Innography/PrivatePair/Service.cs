using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class Service
    {
        [JsonProperty("service_id")]
        public string ServiceId { get; set; }

        [JsonIgnore]
        public bool IsValid => !string.IsNullOrWhiteSpace(ServiceId);
    }
}