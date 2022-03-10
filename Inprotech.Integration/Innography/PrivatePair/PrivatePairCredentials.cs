using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class PrivatePairCredentials 
    {
        [JsonProperty("sponsor")]
        public string Sponsor { get; set; }

        [JsonProperty("uspto_username")]
        public string Email { get; set; }

        [JsonProperty("uspto_password")]
        public string Password { get; set; }

        [JsonProperty("secret")]
        public string SecretCode { get; set; }

        [JsonProperty("pubkey")]
        public string PublicKey { get; set; }

        [JsonProperty("customer_numbers")]
        public Dictionary<string, string[]> CustomerNumbers { get; set; }
    }
}