using System.Collections.Generic;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search
{
    public class WipOverviewSearchRequestFilter : SearchRequestFilter
    {
        public IEnumerable<WipOverviewSearchRequest> SearchRequest { get; set; }
    }

    public class WipOverviewSearchRequest
    {
        public SearchElement RowKeys { get; set; }
    }
}