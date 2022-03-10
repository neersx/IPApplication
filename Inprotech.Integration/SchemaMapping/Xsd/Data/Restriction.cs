using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.SchemaMapping.Xsd.Data
{
    public class Restriction
    {        
        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string Pattern { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string Length { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string MinLength { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string MaxLength { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string MaxExclusive { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string MaxInclusive { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string MinExclusive { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string MinInclusive { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string TotalDigits { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public IEnumerable<string> Enumerations { get; internal set; }        
    }
}