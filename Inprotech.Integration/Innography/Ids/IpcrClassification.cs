using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.Ids
{
    public class IpcrClassification
    {
        public string ClassificationType { get; set; }
        
        [JsonProperty("class_code")]
        public string ClassCode { get; set; }

        [JsonProperty("sub_class_code")]
        public string SubClassCode { get; set; }
        
        [JsonProperty("main_group")]
        public string MainGroup { get; set; }

        [JsonProperty("sub_group")]
        public string SubGroup { get; set; }

        public string Section { get; set; }
    }
}