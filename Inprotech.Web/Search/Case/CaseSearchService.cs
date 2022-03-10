using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search.Case
{
    public interface ICaseSearchService
    {
        Task<SearchResult> GetRecentCaseSearchResult(CommonQueryParameters queryParameters);
        Task<SearchResult> GetDueDateOnlyCaseSearchResult(int queryKey, CaseSearchRequestFilter req, CommonQueryParameters queryParameters);
        (bool HasDueDatePresentationColumn, bool HasAllDatePresentationColumn) DueDatePresentationColumn(int? queryKey);
        IEnumerable<KeyValuePair<string, string>> GetImportanceLevels();
        Task<SearchResult> GlobalCaseChangeResults(CommonQueryParameters queryParameters, int globalProcessKey, string searchPresentationType);
        Task<SearchExportData> GlobalCaseChangeResultsExportData(CommonQueryParameters queryParameters, int globalProcessKey, string searchPresentationType);
        void UpdateFilterForBulkOperation(SearchExportParams<CaseSearchRequestFilter> searchExportParams);
        Task<IEnumerable<int>> DistinctCaseIdsForBulkOperations(SearchExportParams<CaseSearchRequestFilter> request);
    }

    public class CaseSearchService : ICaseSearchService
    {
        readonly IDbContext _dbContext;
        readonly int _defaultCaseSearchQueryKey;
        readonly IImportanceLevelResolver _importanceLevelResolver;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IPresentationColumnsResolver _presentationColumnsResolver;
        readonly ISearchPresentationService _presentationService;
        readonly ISearchService _searchService;

        readonly QueryContext _queryContext;
        readonly ISearch _search;
        readonly ISecurityContext _securityContext;
        
        readonly IXmlFilterCriteriaBuilderResolver _filterCriteriaBuilderResolver;
        readonly IFilterableColumnsMapResolver _filterableColumnsMapResolver;

        public CaseSearchService(IDbContext dbContext,
                                 ISecurityContext securityContext,
                                 IPreferredCultureResolver preferredCultureResolver,
                                 ISearch search,
                                 ISearchPresentationService presentationService,
                                 IPresentationColumnsResolver presentationColumnsResolver,
                                 IImportanceLevelResolver importanceLevelResolver,
                                 ISearchService searchService, 
                                 IXmlFilterCriteriaBuilderResolver filterCriteriaBuilderResolver,
                                 IFilterableColumnsMapResolver filterableColumnsMapResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _search = search;
            _presentationService = presentationService;
            _presentationColumnsResolver = presentationColumnsResolver;
            _importanceLevelResolver = importanceLevelResolver;
            _searchService = searchService;
            _filterCriteriaBuilderResolver = filterCriteriaBuilderResolver;
            _filterableColumnsMapResolver = filterableColumnsMapResolver;

            _queryContext = GetQueryContext();
            _defaultCaseSearchQueryKey = GetDefaultQuery();
        }

        public IEnumerable<KeyValuePair<string, string>> GetImportanceLevels()
        {
            var defaultImportanceLevel = _importanceLevelResolver.Resolve();
            var culture = _preferredCultureResolver.Resolve();

            var importance = _dbContext.Set<Importance>()
                                       .Select(_ => new
                                       {
                                           _.Level,
                                           Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                       })
                                       .ToArray();

            return importance.Select(_ => new Importance(_.Level, _.Description))
                             .Where(_ => _.LevelNumeric.HasValue && _.LevelNumeric.Value >= (_securityContext.User.IsExternalUser ? defaultImportanceLevel : 0))
                             .OrderBy(_ => _.LevelNumeric).Select(_ => new KeyValuePair<string, string>(_.Level, _.Description));
        }

        public async Task<SearchResult> GlobalCaseChangeResults(CommonQueryParameters queryParameters, int globalProcessKey, string presentationType)
        {
            var presentation = await _presentationService.GetSearchPresentation(_queryContext, presentationType: presentationType);
            presentation.XmlCriteria = CaseSearchHelper.ConstructGlobalCaseChangeCriteria(globalProcessKey);

            return await _search.GetFormattedSearchResults<CaseSearchRequestFilter>(null, presentation, queryParameters);
        }

        public async Task<SearchExportData> GlobalCaseChangeResultsExportData(CommonQueryParameters queryParameters, int globalProcessKey, string presentationType)
        {
            var presentation = await _presentationService.GetSearchPresentation(_queryContext, presentationType: presentationType);
            presentation.XmlCriteria = CaseSearchHelper.ConstructGlobalCaseChangeCriteria(globalProcessKey);

            return new SearchExportData
            {
                SearchResults = await _search.GetSearchResults<CaseSearchRequestFilter>(null, presentation, queryParameters),
                Presentation = presentation
            };
        }

        public async Task<SearchResult> GetRecentCaseSearchResult(CommonQueryParameters queryParameters)
        {
            var presentation = await _presentationService.GetSearchPresentation(_queryContext, _defaultCaseSearchQueryKey);
            _presentationService.UpdatePresentationForColumnSort(presentation, queryParameters.SortBy, queryParameters.SortDir);

            return await _search.GetFormattedSearchResults<CaseSearchRequestFilter>(null, presentation, queryParameters);
        }

        public async Task<SearchResult> GetDueDateOnlyCaseSearchResult(int queryKey, CaseSearchRequestFilter req, CommonQueryParameters queryParameters)
        {
            var presentation = await _presentationService.GetSearchPresentation(_queryContext, queryKey);
            presentation.XmlCriteria = CaseSearchHelper.AddReplaceDueDateFilter(presentation.XmlCriteria, req.DueDateFilter);

            return await _search.GetFormattedSearchResults<CaseSearchRequestFilter>(null, presentation, queryParameters);
        }

        public (bool HasDueDatePresentationColumn, bool HasAllDatePresentationColumn) DueDatePresentationColumn(int? queryKey)
        {
            var presentationColumns = _presentationColumnsResolver.Resolve(queryKey, _queryContext);

            var dueDateGroupId = _queryContext == QueryContext.CaseSearch ? -44 : -45;

            var enumerable = presentationColumns as PresentationColumn[] ?? presentationColumns.ToArray();
            var dueDateQueryContextColumns = _dbContext.Set<QueryContextColumn>()
                                                       .Where(qcc => qcc.GroupId == dueDateGroupId)
                                                       .Select(_ => _.ColumnId);

            var hasDueDatePresentationColumn = enumerable.Any(_ => dueDateQueryContextColumns.Contains(_.ColumnKey));

            var hasAllDatePresentationColumn = enumerable.Any(_ => KnownAllDatePresentationColumns.AllDatesColumns.Contains(_.ProcedureItemId.ToUpper()));

            return (HasDueDatePresentationColumn: hasDueDatePresentationColumn,
                HasAllDatePresentationColumn: hasAllDatePresentationColumn);
        }

        public void UpdateFilterForBulkOperation(SearchExportParams<CaseSearchRequestFilter> searchExportParams)
        {
            if (searchExportParams.QueryKey != null && searchExportParams.Criteria.SearchRequest?.First().CaseReference == null)
            {
                string xmlFilterCriteria;
                if (!string.IsNullOrEmpty(searchExportParams.Criteria.XmlSearchRequest))
                {
                    xmlFilterCriteria = searchExportParams.Criteria.XmlSearchRequest;
                }
                else if (searchExportParams.Criteria.SearchRequest != null && searchExportParams.Criteria.SearchRequest.Any())
                {
                    var filterableColumnsMap = _filterableColumnsMapResolver.Resolve(searchExportParams.QueryContext);
                   
                    xmlFilterCriteria = _filterCriteriaBuilderResolver.Resolve(searchExportParams.QueryContext)
                                                                      .Build(searchExportParams.Criteria, new CommonQueryParameters(), filterableColumnsMap);
                    
                }
                else
                {
                    var query = _dbContext.Set<Query>().Single(_ => _.Id == searchExportParams.QueryKey);
                    xmlFilterCriteria = _dbContext.Set<QueryFilter>().Single(_ => _.Id == query.FilterId).XmlFilterCriteria;
                }
                
                if (searchExportParams.Criteria.DueDateFilter != null)
                    xmlFilterCriteria = CaseSearchHelper.AddReplaceDueDateFilter(xmlFilterCriteria, searchExportParams.Criteria.DueDateFilter);

                xmlFilterCriteria = CaseSearchHelper.AddStepToFilterCases(searchExportParams.DeselectedIds, xmlFilterCriteria);

                searchExportParams.Criteria.XmlSearchRequest = xmlFilterCriteria;
            }
            else if (searchExportParams.DeselectedIds != null && searchExportParams.DeselectedIds.Length > 0)
            {
                if (!string.IsNullOrWhiteSpace(searchExportParams.Criteria.XmlSearchRequest))
                {
                    searchExportParams.Criteria.XmlSearchRequest = CaseSearchHelper.AddStepToFilterCases(searchExportParams.DeselectedIds, searchExportParams.Criteria.XmlSearchRequest);
                }
                else
                {
                    var request = searchExportParams.Criteria.SearchRequest.ToList();
                    request.Add(new CaseSearchRequest
                    {
                        IncludeDraftCase = 0,
                        Id = request.Count + 1,
                        Operator = "AND",
                        CaseKeys = new SearchElement
                        {
                            Operator = (short)CollectionExtensions.FilterOperator.NotIn,
                            Value = string.Join(",", searchExportParams.DeselectedIds)
                        }
                    });
                    searchExportParams.Criteria.SearchRequest = request;
                    searchExportParams.ForceConstructXmlCriteria = true;
                }
            }
        }

        public async Task<IEnumerable<int>> DistinctCaseIdsForBulkOperations(SearchExportParams<CaseSearchRequestFilter> request)
        {
            request.SelectedColumns = SelectedColumnWithCaseReference();

            var result = await _searchService.RunSearch(request);

            if (!result.Rows.Any())
                throw new ArgumentException("Invalid Request");

            return result.Rows.Select(r => (int)r["CaseKey"]).ToList().Distinct().ToList();
        }

        IEnumerable<SelectedColumn> SelectedColumnWithCaseReference()
        {
            var columnId = _presentationColumnsResolver.AvailableColumns(_queryContext)
                                                       .First(_ => _.ProcedureItemId.ToLower().Equals("casereference")).ColumnKey;
            return new List<SelectedColumn> { new SelectedColumn { ColumnKey = columnId } };
        }

        QueryContext GetQueryContext()
        {
            return _securityContext.User.IsExternalUser
                ? QueryContext.CaseSearchExternal
                : QueryContext.CaseSearch;
        }

        int GetDefaultQuery()
        {
            return _securityContext.User.IsExternalUser
                ? -1
                : -2;
        }
    }
}