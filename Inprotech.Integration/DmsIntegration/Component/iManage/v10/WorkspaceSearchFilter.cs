using Newtonsoft.Json;

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v10
{
    public class WorkspaceSearchFilter
    {
        [JsonProperty("custom1")]
        public string Custom1 { get; set; }

        [JsonProperty("custom2")]
        public string Custom2 { get; set; }

        [JsonProperty("custom3")]
        public string Custom3 { get; set; }

        [JsonProperty("libraries")]
        public string Libraries { get; set; }

        [JsonProperty("subclass")]
        public string SubClass { get; set; }
    }
}
