using System;

namespace Inprotech.Web.Search
{
    public interface ISearchTypeParser
    {
        int Parse(string searchType);
    }

    public class SearchTypeParser : ISearchTypeParser
    {
        const string QuickSearch = "quick-search";
        const string StandardSearch = "standard-search";

        public int Parse(string searchType)
        {
            switch(searchType)
            {
                case QuickSearch:
                    return SearchConstants.SearchTypeQuickSearch;
                case StandardSearch:
                    return SearchConstants.SearchTypeStandardSearch;
            }

            throw new ArgumentException(string.Format("invalid search type: {0}", searchType));
        }
    }
}