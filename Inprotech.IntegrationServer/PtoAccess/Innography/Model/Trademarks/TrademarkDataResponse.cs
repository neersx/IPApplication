using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks
{
    public class TrademarkDataResponse : TrademarkData
    {
        [JsonProperty(PropertyName = "client_index")]
        public string ClientIndex { get; set; }

        [JsonProperty(PropertyName = "ipid")]
        public string IpId { get; set; }

        [JsonProperty(PropertyName = "match")]
        public string Match { get; set; }
    }

    public static class TrademarkExtensions
    {
        public static bool HasInvalidInnographyId(this TrademarkDataResponse result)
        {
            return string.IsNullOrWhiteSpace(result?.IpId) || result.IpId?.Trim() == "0";
        }
    }
}
