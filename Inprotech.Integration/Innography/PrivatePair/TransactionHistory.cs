using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class TransactionHistory
    {
        [JsonProperty("description")]
        public string Description { get; set; }

        [JsonProperty("date_action")]
        public string DateAction { get; set; }
    }
}