using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class GetMessagesResponse
    {
        [JsonProperty("messages")]
        public IEnumerable<Message> Messages { get; set; }
    }
}