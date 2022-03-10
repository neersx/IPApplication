using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search
{
    public interface ISearchService
    {
        Task<SearchResult> RunSearch<T>(SearchRequestParams<T> searchRequestParams) where T : SearchRequestFilter;
        Task<SearchResult> RunSavedSearch<T>(SavedSearchRequestParams<T> searchRequestParams) where T : SearchRequestFilter;
        Task<SearchResult> RunEditedSavedSearch<T>(SavedSearchRequestParams<T> searchRequestParams, bool forceConstructXmlCriteria = false) where T : SearchRequestFilter;
        Task<SearchExportData> GetSearchExportData<T>(T req, CommonQueryParameters queryParameters, int? queryKey, QueryContext queryContext, IEnumerable<SelectedColumn> selectedColumns, bool forceConstructXmlCriteria = false) where T : SearchRequestFilter;
        Task<IEnumerable<SearchResult.Column>> GetSearchColumns(QueryContext queryContext, int? queryKey, IEnumerable<SelectedColumn> selectedColumns, string searchPresentationType);
        Task<IEnumerable<CodeDescription>> GetFilterDataForColumn<T>(ColumnFilterParams<T> columnFilterParams) where T : SearchRequestFilter;
    }

    public class SearchService : ISearchService
    {
        readonly ISearchPresentationService _presentation;
        readonly ISavedSearchValidator _savedSearchValidator;
        readonly ISearch _search;

        public SearchService(
            ISearch search,
            ISearchPresentationService presentation,
            ISavedSearchValidator savedSearchValidator)
        {
            _search = search;
            _presentation = presentation;
            _savedSearchValidator = savedSearchValidator;
        }

        public async Task<IEnumerable<SearchResult.Column>> GetSearchColumns(QueryContext queryContext, int? queryKey, IEnumerable<SelectedColumn> selectedColumns, string searchPresentationType)
        {
            var presentation = await _presentation.GetSearchPresentation(queryContext, queryKey, selectedColumns, searchPresentationType);

            return presentation.ColumnFormats.ToSearchColumn();
        }

        public async Task<SearchExportData> GetSearchExportData<T>(T req, CommonQueryParameters queryParameters, int? queryKey, QueryContext queryContext, IEnumerable<SelectedColumn> selectedColumns, bool forceConstructXmlCriteria = false) where T : SearchRequestFilter
        {
            var presentation = queryKey.HasValue
                ? await _presentation.GetSearchPresentation(queryContext, queryKey, selectedColumns)
                : await _presentation.GetSearchPresentation(queryContext, selectedColumns: selectedColumns);

            _presentation.UpdatePresentationForColumnSort(presentation, queryParameters.SortBy, queryParameters.SortDir);

            PopulateFiltersWithCode(queryParameters, queryContext);

            var searchResults = await _search.GetSearchResults(req, presentation, queryParameters, forceConstructXmlCriteria);

            return new SearchExportData
            {
                SearchResults = searchResults,
                Presentation = presentation
            };
        }

        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn<T>(ColumnFilterParams<T> columnFilterParams) where T : SearchRequestFilter
        {
            if (columnFilterParams == null) throw new ArgumentNullException(nameof(columnFilterParams));
            if (string.IsNullOrWhiteSpace(columnFilterParams.Column)) return new List<CodeDescription>();
            if (columnFilterParams.Criteria == null) return new List<CodeDescription>();

            var extractedColumnName = ExtractColumnName(columnFilterParams.Column);
            var columnCodeKey = _presentation.GetMatchingColumnCode(columnFilterParams.QueryContext, extractedColumnName);
            columnCodeKey = extractedColumnName.Equals(columnCodeKey, StringComparison.CurrentCultureIgnoreCase) ? columnFilterParams.Column : columnCodeKey;

            var presentation = await _presentation.GetSearchPresentation(columnFilterParams.QueryContext, columnFilterParams.QueryKey,  columnFilterParams.SelectedColumns);
            _presentation.UpdatePresentationForColumnFilterData(presentation, columnFilterParams.Column, columnCodeKey);

            var queryParameters = columnFilterParams.Params;

            queryParameters.Skip = null;
            queryParameters.Take = null;

            // Remove current column from the filter context
            queryParameters.Filters = queryParameters.Filters.Where(f => !f.Field.IgnoreCaseEquals(columnFilterParams.Column) && !f.Field.IgnoreCaseContains(columnFilterParams.Column));

            PopulateFiltersWithCode(queryParameters, columnFilterParams.QueryContext);

            var result = await _search.GetSearchResults(columnFilterParams.Criteria, presentation, queryParameters);
            return result.Rows.Select(r => new CodeDescription
                         {
                            Code = r.ContainsKey(columnCodeKey) ? r[columnCodeKey].ToString() : string.Empty,
                            Description = r.ContainsKey(columnFilterParams.Column) ? r[columnFilterParams.Column].ToString() : string.Empty
                         })
                         .DistinctBy(r => r.Code)
                         .Where(r => !string.IsNullOrWhiteSpace(r.Code)) // csw_ListCase doesn't support filter on space & other values
                         .OrderBy(r => r.Description)
                         .ToArray();
        }

        public async Task<SearchResult> RunSavedSearch<T>(SavedSearchRequestParams<T> searchRequestParams) where T : SearchRequestFilter
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            await _savedSearchValidator.ValidateQueryExists(searchRequestParams.QueryContext, searchRequestParams.QueryKey.GetValueOrDefault(), true);

            return await GetSearchResult(searchRequestParams.Params ?? new CommonQueryParameters(),
                                         searchRequestParams.QueryContext,
                                         searchRequestParams.SelectedColumns,
                                         searchRequestParams.Criteria,
                                         searchRequestParams.QueryKey);
        }

        public async Task<SearchResult> RunEditedSavedSearch<T>(SavedSearchRequestParams<T> searchRequestParams, bool forceConstructXmlCriteria = false) where T : SearchRequestFilter
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            await _savedSearchValidator.ValidateQueryExists(searchRequestParams.QueryContext, searchRequestParams.QueryKey.GetValueOrDefault(), true);

            if (searchRequestParams.Criteria == null) return new SearchResult();

            return await GetSearchResult(searchRequestParams.Params ?? new CommonQueryParameters(),
                                         searchRequestParams.QueryContext,
                                         searchRequestParams.SelectedColumns,
                                         searchRequestParams.Criteria,
                                         searchRequestParams.QueryKey, null, forceConstructXmlCriteria);
        }

        public async Task<SearchResult> RunSearch<T>(SearchRequestParams<T> searchRequestParams) where T : SearchRequestFilter
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.Criteria == null) return new SearchResult();

            return await GetSearchResult(searchRequestParams.Params ?? new CommonQueryParameters(),
                                         searchRequestParams.QueryContext,
                                         searchRequestParams.SelectedColumns,
                                         searchRequestParams.Criteria,
                                         searchPresentationType: searchRequestParams.Criteria.PresentationType);
        }

        async Task<SearchResult> GetSearchResult<T>(CommonQueryParameters queryParameters, QueryContext queryContext, IEnumerable<SelectedColumn> selectedColumns = null, T req = default(T), int? queryKey = null, string searchPresentationType = null, bool forceConstructXmlCriteria = false) where T : SearchRequestFilter
        {
            var presentation = await _presentation.GetSearchPresentation(queryContext, queryKey, selectedColumns, searchPresentationType);

            _presentation.UpdatePresentationForColumnSort(presentation, queryParameters.SortBy, queryParameters.SortDir);

            PopulateFiltersWithCode(queryParameters, queryContext);

            if (!string.IsNullOrWhiteSpace(req?.XmlSearchRequest))
            {
                presentation.XmlCriteria = req.XmlSearchRequest;
            }

            return await _search.GetFormattedSearchResults(req, presentation, queryParameters, forceConstructXmlCriteria);
        }

        void PopulateFiltersWithCode(CommonQueryParameters queryParameters, QueryContext queryContext)
        {
            if (queryParameters.Filters == null || !queryParameters.Filters.Any()) return;

            foreach (var filter in queryParameters.Filters) filter.Field = _presentation.GetMatchingColumnCode(queryContext, ExtractColumnName(filter.Field));
        }

        static string ExtractColumnName(string columnId)
        {
            return columnId.Contains('_') ? columnId.Substring(0, columnId.IndexOf('_')) : columnId;
        }
    }

    public class SearchExportData
    {
        public SearchResults SearchResults { get; set; }
        public SearchPresentation Presentation { get; set; }
    }
}