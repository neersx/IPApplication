using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using Inprotech.Web.Search.TaskPlanner;
using InprotechKaizen.Model.Components.Cases.Reminders.Search;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner
{
    public class TaskPlannerRowSelectionServiceFacts
    {
        public class GetSelectedTaskPlannerRowKeysMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnSameRowKeysIfSearchParamsIsNull()
            {
                var fixture = new TaskPlannerRowSelectionFixture();
                var taskPlannerRowKeys = new[] { "C^567^90^14^125^89" };
                var reminderAction = new ReminderActionRequest { TaskPlannerRowKeys = taskPlannerRowKeys };
                var result = await fixture.Subject.GetSelectedTaskPlannerRowKeys(reminderAction);
                Assert.Equal(1, result.Length);
                Assert.Equal(taskPlannerRowKeys[0], result[0]);
            }

            [Fact]
            public async Task ShouldCallRunSavedSearchIfQueryKeyNotPresentAndCriteriaIsNull()
            {
                var fixture = new TaskPlannerRowSelectionFixture();
                var searchParams = new SavedSearchRequestParams<TaskPlannerRequestFilter>
                {
                    QueryKey = 1,
                    Params = new CommonQueryParameters()
                };
                var reminderAction = new ReminderActionRequest { SearchRequestParams = searchParams };

                fixture.SearchService.RunSavedSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>()).ReturnsForAnyArgs(new SearchResult()
                {
                    Rows = new List<Dictionary<string, object>>()
                });

                await fixture.Subject.GetSelectedTaskPlannerRowKeys(reminderAction);

                fixture.SearchService.Received(1).RunSavedSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>());
                fixture.SearchService.Received(0).RunEditedSavedSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>());
                fixture.SearchService.Received(0).RunSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>());
            }

            [Fact]
            public async Task ShouldCallRunEditSavedSearchIfQueryKeyPresentAndCriteriaIsPresent()
            {
                var fixture = new TaskPlannerRowSelectionFixture();
                var searchParams = new SavedSearchRequestParams<TaskPlannerRequestFilter>
                {
                    QueryKey = 1,
                    Criteria = new TaskPlannerRequestFilter(),
                    Params = new CommonQueryParameters()
                };
                var reminderAction = new ReminderActionRequest { SearchRequestParams = searchParams };

                fixture.SearchService.RunEditedSavedSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>()).ReturnsForAnyArgs(new SearchResult()
                {
                    Rows = new List<Dictionary<string, object>>()
                });

                await fixture.Subject.GetSelectedTaskPlannerRowKeys(reminderAction);

                fixture.SearchService.Received(0).RunSavedSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>());
                fixture.SearchService.Received(1).RunEditedSavedSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>());
                fixture.SearchService.Received(0).RunSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>());
            }

            [Fact]
            public async Task ShouldCallRunSearchIfQueryKeyNotPresentAndCriteriaIsPresent()
            {
                var fixture = new TaskPlannerRowSelectionFixture();
                var searchParams = new SavedSearchRequestParams<TaskPlannerRequestFilter>
                {
                    Criteria = new TaskPlannerRequestFilter(),
                    Params = new CommonQueryParameters()
                };
                var reminderAction = new ReminderActionRequest { SearchRequestParams = searchParams };

                fixture.SearchService.RunSavedSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>()).ReturnsForAnyArgs(new SearchResult()
                {
                    Rows = new List<Dictionary<string, object>>()
                });

                fixture.Subject.GetSelectedTaskPlannerRowKeys(reminderAction);

                fixture.SearchService.Received(0).RunSavedSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>());
                fixture.SearchService.Received(0).RunEditedSavedSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>());
                fixture.SearchService.Received(1).RunSearch(Arg.Any<SavedSearchRequestParams<TaskPlannerRequestFilter>>());
            }
        }
    }

    public class TaskPlannerRowSelectionFixture : IFixture<ITaskPlannerRowSelectionService>
    {
        public TaskPlannerRowSelectionFixture()
        {
            SearchService = Substitute.For<ISearchService>();
            Subject = new TaskPlannerRowSelectionService(SearchService);
        }

        public ISearchService SearchService { get; set; }
        public ITaskPlannerRowSelectionService Subject { get; }
    }
}