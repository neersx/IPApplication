using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks
{
    public class TrademarkImage
    {
        [JsonProperty("content")]
        public string Content { get; set; }

        [JsonProperty("type")]
        public string Type { get; set; }
    }
}
