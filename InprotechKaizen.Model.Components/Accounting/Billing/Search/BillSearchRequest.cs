using System.Collections.Generic;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Search
{

    public class BillSearchRequestFilter : SearchRequestFilter
    {
        public IEnumerable<BillSearchRequest> SearchRequest { get; set; }
    }

    public class BillSearchRequest
    {
        public SearchElement RowKeys { get; set; }
    }
}
