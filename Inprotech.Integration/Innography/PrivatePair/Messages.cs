using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class Messages
    {
        [JsonProperty("messages")]
        public IEnumerable<Message> MessageArray { get; set; }
    }
}