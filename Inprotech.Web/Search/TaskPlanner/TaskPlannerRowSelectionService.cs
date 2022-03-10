using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.Reminders.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.TaskPlanner
{
    public interface ITaskPlannerRowSelectionService
    {
        Task<string[]> GetSelectedTaskPlannerRowKeys(ReminderActionRequest request);
    }

    public class TaskPlannerRowSelectionService : ITaskPlannerRowSelectionService
    {
        readonly ISearchService _searchService;

        public TaskPlannerRowSelectionService(ISearchService searchService)
        {
            _searchService = searchService;
        }
        
        public async Task<string[]> GetSelectedTaskPlannerRowKeys(ReminderActionRequest request)
        {
            var searchRequestParams = request.SearchRequestParams;
            if (searchRequestParams == null) return request.TaskPlannerRowKeys;

            if (searchRequestParams.Criteria?.DeselectedIds != null && searchRequestParams.Criteria.DeselectedIds.Any())
            {
                var taskPlannerRowKeys = new SearchElement
                {
                    Value = string.Join(",", searchRequestParams.Criteria.DeselectedIds),
                    Operator = (short)CollectionExtensions.FilterOperator.NotIn
                };
                var searchRequest = searchRequestParams.Criteria.SearchRequest ?? new TaskPlannerRequest();

                searchRequest.RowKeys = taskPlannerRowKeys;
                searchRequestParams.Criteria.SearchRequest = searchRequest;
            }
            else
            {
                searchRequestParams.Params.Take = null;
                searchRequestParams.Params.Skip = null;
            }

            var selectedRows = await RunSearch(searchRequestParams);
            var selectedRowKeys = selectedRows.Rows.Select(x => Convert.ToString(x["TaskPlannerRowKey"])).ToArray();

            return selectedRowKeys;
        }

        async Task<SearchResult> RunSearch(SavedSearchRequestParams<TaskPlannerRequestFilter> searchRequestParams)
        {
            if (searchRequestParams.QueryKey.HasValue && searchRequestParams.Criteria == null)
            {
                return await _searchService.RunSavedSearch(searchRequestParams);
            }

            if (searchRequestParams.QueryKey.HasValue && searchRequestParams.Criteria != null)
            {
                return await _searchService.RunEditedSavedSearch(searchRequestParams);
            }

            return await _searchService.RunSearch(searchRequestParams);
        }
    }
}
