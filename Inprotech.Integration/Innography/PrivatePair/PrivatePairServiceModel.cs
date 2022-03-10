using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class PrivatePairServiceModel
    {
        
        [JsonProperty("uspto_password")]
        public string Password { get; set; }

        [JsonProperty("secret")]
        public string Secret { get; set; }

        [JsonProperty("pubkey")]
        public string PublicKey { get; set; }

        [JsonProperty("customer_numbers")]
        public Dictionary<string, string[]> CustomerNumbers { get; set; }

        [JsonProperty("test_data")]
        public bool TestData { get; set; }
    }
}