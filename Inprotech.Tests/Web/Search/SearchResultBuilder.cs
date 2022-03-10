using System.Collections.Generic;
using Inprotech.Tests.Web.Builders;
using Inprotech.Web.Search;
using Newtonsoft.Json.Linq;

namespace Inprotech.Tests.Web.Search
{
    public class SearchResultBuilder : IBuilder<QuickSearchResult>
    {
        readonly List<Column> _columns = new List<Column>();
        readonly List<JObject> _rows = new List<JObject>();

        public string GetResultsResponse { get; set; }

        public string GetSearchResponse { get; set; }

        public int TotalCount { get; set; }

        public QuickSearchResult Build()
        {
            return new QuickSearchResult
            {
                Columns = _columns,
                Rows = _rows,
                TotalCount = TotalCount,
                GetResultsResponse = GetResultsResponse,
                GetSearchResponse = GetSearchResponse
            };
        }

        public SearchResultBuilder WithColumn(Column column)
        {
            _columns.Add(column);

            return this;
        }

        public SearchResultBuilder WithRow(object row)
        {
            _rows.Add(JObject.FromObject(row));

            return this;
        }
    }
}