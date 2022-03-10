using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks
{
    public class TrademarkDataRequest : TrademarkData
    {
        static int _clientIndex;

        public TrademarkDataRequest()
        {
            _clientIndex += 1;

            ClientIndex = _clientIndex.ToString();
        }

        [JsonProperty(PropertyName = "client_index")]
        public string ClientIndex { get; set; }
    }
}
