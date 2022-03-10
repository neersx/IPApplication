using Newtonsoft.Json;

namespace Inprotech.Integration.IPPlatform.FileApp.Models
{
    public class BibloClasses
    {
        [JsonProperty("id")]
        public int Id { get; set; }

        [JsonProperty("description")]
        public string Description { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }
    }
}