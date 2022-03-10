using System.Collections.Generic;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Names.Search
{
    public class NameSearchRequestFilter<T> : SearchRequestFilter
    {
        public IEnumerable<T> SearchRequest { get; set; }
    }

    public class NameSearchRequest : NameSearchRequestBase
    {

    }

    public class NameSearchRequestBase
    {
        public int Id { get; set; }

        public string Operator { get; set; }

        public SearchElement AnySearch { get; set; }

        public SearchElement NameKeys { get; set; }

        public string[] NameKeysArr => NameKeys == null || string.IsNullOrWhiteSpace(NameKeys.Value) ? null : NameKeys.Value.Split(',');

        public bool IsCurrent { get; set; } = true;

        public bool IsCeased { get; set; }

        public bool? IsLead { get; set; }
    }
}