using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.Ids
{
    public class Result
    {
        [JsonProperty("documents")]
        public DocumentDetails[] DocumentDetails { get; set; }
    }
}