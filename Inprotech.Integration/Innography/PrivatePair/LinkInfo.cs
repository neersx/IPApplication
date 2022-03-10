using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class LinkInfo
    {
        [JsonProperty("type")]
        public string LinkType { get; set; }

        [JsonProperty("status")]
        public string Status { get; set; }

        [JsonProperty("message")]
        public string Message { get; set; }

        [JsonProperty("link")]
        public string Link { get; set; }

        [JsonProperty("decrypter")]
        public string Decrypter { get; set; }

        [JsonProperty("iv")]
        public string Iv { get; set; }
    }

    public class LinkTypes
    {
        public const string Pdf = "pdf";
        public const string Biblio = "biblio";
    }
}