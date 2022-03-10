using System.Collections.Generic;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Cases.PriorArt.Search
{
    public class PriorArtSearchRequestFilter : SearchRequestFilter
    {
        public IEnumerable<PriorArtSearchRequest> SearchRequest { get; set; }
    }

    public class PriorArtSearchRequest
    {
        public SearchElement AnySearch { get; set; }

        public SearchElement PriorArtKeys { get; set; } 
    }
}