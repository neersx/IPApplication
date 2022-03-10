using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks
{
    public class TrademarkDataValidationRequest : TrademarkData
    {
        static int _clientIndex;

        public TrademarkDataValidationRequest()
        {
            _clientIndex += 1;

            ClientIndex = _clientIndex.ToString();
        }

        [JsonProperty(PropertyName = "client_index")]
        public string ClientIndex { get; set; }
        
        [JsonProperty(PropertyName = "ipid")]
        public string IpId { get; set; }
    }
}
