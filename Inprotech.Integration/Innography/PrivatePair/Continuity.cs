using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class Continuity
    {
        [JsonProperty("parent_number")]
        public string ApplicationNumber { get; set; }

        [JsonProperty("patent_number")]
        public string PatentNumber { get; set; }

        [JsonProperty("parent_371date")]
        public string FilingDate371 { get; set; }

        [JsonProperty("parent_status")]
        public string ContinuityStatus { get; set; }

        [JsonProperty("description")]
        public string Description { get; set; }

        [JsonProperty("claim_parentage_type")]
        public string ClaimParentageType { get; set; }
    }
}