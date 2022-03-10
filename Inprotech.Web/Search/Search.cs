using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search
{
    public interface ISearch
    {
        Task<SearchResults> GetSearchResults<T>(T req, SearchPresentation presentation,
                                          CommonQueryParameters queryParameters, bool forceConstructXmlCriteria = false) where T : SearchRequestFilter // TODO Force only after editSavedSearchResult
        ;

        Task<SearchResult> GetFormattedSearchResults<T>(T req, SearchPresentation presentation,
                                                  CommonQueryParameters queryParameters, bool forceConstructXmlCriteria = false) where T : SearchRequestFilter // TODO Force only after editSavedSearchResult
        ;
    }

    public class Search : ISearch
    {
        readonly IXmlFilterCriteriaBuilderResolver _filterCriteriaBuilderResolver;
        readonly IFilterableColumnsMapResolver _filterableColumnsMapResolver;
        readonly ISearchDataProvider _searchDataProvider;

        public Search(ISearchDataProvider searchDataProvider,
                      IXmlFilterCriteriaBuilderResolver filterCriteriaBuilderResolver,
                      IFilterableColumnsMapResolver filterableColumnsMapResolver)
        {
            _searchDataProvider = searchDataProvider;
            _filterCriteriaBuilderResolver = filterCriteriaBuilderResolver;
            _filterableColumnsMapResolver = filterableColumnsMapResolver;
        }

        public async Task<SearchResults> GetSearchResults<T>(T req, SearchPresentation presentation,
                                                 CommonQueryParameters queryParameters, bool forceConstructXmlCriteria = false) where T : SearchRequestFilter // TODO Force only after editSavedSearchResult
        {
            if (!string.IsNullOrWhiteSpace(req?.XmlSearchRequest))
            {
                presentation.XmlCriteria = req.XmlSearchRequest;
            }

            if (string.IsNullOrEmpty(presentation.XmlCriteria) || forceConstructXmlCriteria)
            {
                var filterableColumnsMap = _filterableColumnsMapResolver.Resolve(presentation.QueryContextKey);
                presentation.XmlCriteria = _filterCriteriaBuilderResolver.Resolve(presentation.QueryContextKey)
                                                                         .Build(req, queryParameters, filterableColumnsMap);
            }
            else if (!string.IsNullOrEmpty(presentation.XmlCriteria))
            {
                var filterableColumnsMap = _filterableColumnsMapResolver.Resolve(presentation.QueryContextKey);
                presentation.XmlCriteria = _filterCriteriaBuilderResolver.Resolve(presentation.QueryContextKey)
                                                                         .Build(req, presentation.XmlCriteria, queryParameters, filterableColumnsMap);
            }

            return await _searchDataProvider.RunSearch(presentation, queryParameters);
        }

        public async Task<SearchResult> GetFormattedSearchResults<T>(T req, SearchPresentation presentation,
                                                         CommonQueryParameters queryParameters, bool forceConstructXmlCriteria = false) where T : SearchRequestFilter // TODO Force only after editSavedSearchResult
        {
            var searchResult = await GetSearchResults(req, presentation, queryParameters, forceConstructXmlCriteria);

            return new SearchResult
            {
                XmlCriteriaExecuted = searchResult.XmlCriteriaExecuted,
                TotalRows = searchResult.TotalRows.GetValueOrDefault(),
                Columns = presentation.ColumnFormats.ToSearchColumn(),
                Rows = searchResult.Rows
                                    .Select(x => ReformatSearchResultRow(x, presentation, searchResult.XmlCriteriaExecuted))
                                    .ToList(),
            };
        }

        static Dictionary<string, object> ReformatSearchResultRow(Dictionary<string, object> row, SearchPresentation presentation, string xmlCriteriaExecuted)
        {
            var returnValue = new Dictionary<string, object>();

            foreach (var col in presentation.ColumnFormats)
            {
                if (!row.TryGetValue(col.Id, out var cell)) continue;

                if (!col.Links.Any())
                {
                    returnValue[col.Id.ToLower()] = cell;
                    continue;
                }

                returnValue[col.Id.ToLower()] = new
                {
                    value = cell,
                    link = col.Links[0]
                              .LinkArguments
                              .ToDictionary(k => k.Source, v => row.Get(v.Source))
                };
            }

            // non-presentation columns
            foreach (var cell in row)
            {
                if (presentation.ColumnFormats.All(x => x.Id != cell.Key))
                {
                    returnValue[cell.Key] = cell.Value;
                }
            }

            return returnValue;
        }
    }
}