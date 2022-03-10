using System.Collections.Generic;
using Inprotech.Infrastructure.Web;
using System.Linq;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Search
{
    public class QuickSearchResult
    {
        public QuickSearchResult()
        {
            Columns = Enumerable.Empty<Column>();
            Rows = Enumerable.Empty<JObject>();
        }

        public int TotalCount { get; set; }

        public IEnumerable<Column> Columns { get; set; }

        public IEnumerable<JObject> Rows { get; set; }

        public object GetSearchResponse { get; set; }

        public object GetResultsResponse { get; set; }
    }

    public class Column
    {
        public string Id { get; set; }

        public string Title { get; set; }
    }
}