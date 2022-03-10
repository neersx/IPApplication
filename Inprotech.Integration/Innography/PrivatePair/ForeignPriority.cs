using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class ForeignPriority
    {
        [JsonProperty("country")]
        public string Country { get; set; }

        [JsonProperty("priority")]
        public string ForeignPriorityNumber { get; set; }

        [JsonProperty("priority_date")]
        public string ForeignPriorityDate { get; set; }
    }
}