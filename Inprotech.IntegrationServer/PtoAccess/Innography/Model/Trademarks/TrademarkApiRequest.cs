using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks
{
    public class TrademarkApiRequest<T>
    {
        [JsonProperty("client_id")]
        public string ClientId { get; set; }

        [JsonProperty("requester")]
        public string Requester { get; set; }
        
        [JsonProperty("destination")]
        public string Destination { get; set; }

        [JsonProperty("message_type")]
        public string MessageType { get; set; }
        
        [JsonProperty(PropertyName = "data_fields")]
        public T[] DataFields { get; set; }
    }
}
