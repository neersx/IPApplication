using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Search
{
    public interface ISearchResultSelector
    {
        SearchResult GetActualSelectedRecords(SearchResult searchResult, QueryContext queryContext, int[] deSelectedIds);
    }

    public class SearchResultSelector : ISearchResultSelector
    {
        public SearchResult GetActualSelectedRecords(SearchResult searchResult, QueryContext queryContext, int[] deSelectedIds)
        {
            if (searchResult == null) throw new ArgumentNullException(nameof(searchResult));
            var rowKey = GetRowKeyByQueryContext(queryContext);

            if (string.IsNullOrEmpty(rowKey)) return searchResult;
            var selectedRecords = new List<Dictionary<string, object>>();
            foreach (var r in searchResult.Rows)
            {
                if (deSelectedIds.All(_ => _ != (int) r[rowKey]))
                {
                    selectedRecords.Add(r);
                }
            }
            searchResult.Rows = selectedRecords;
            return searchResult;
        }

        static string GetRowKeyByQueryContext(QueryContext queryContext)
        {
            var rowKey = string.Empty;
            switch (queryContext)
            {
                case QueryContext.WipOverviewSearch:
                    rowKey = "RowKey";
                    break;
            }

            return rowKey;
        }
    }
}