using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search
{
    public interface ISearchController<T> where T : SearchRequestFilter
    {
        Task<SearchResult> RunSearch(SearchRequestParams<T> searchRequestParams);
        Task<SearchResult> RunSavedSearch(SavedSearchRequestParams<T> searchRequestParams);
        Task<SearchResult> RunEditedSavedSearch(SavedSearchRequestParams<T> searchRequestParams);
        Task<IEnumerable<SearchResult.Column>> SearchColumns(ColumnRequestParams columnRequest);
        Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(ColumnFilterParams<T> columnFilterParams);
    }

    public interface IExportableSearchController<T> where T : SearchRequestFilter
    {
        Task Export(SearchExportParams<T> searchExportParams);
    }

    public interface ISearchResultViewController
    {
        Task<dynamic> Get(int? queryKey, QueryContext queryContext);
    }
}