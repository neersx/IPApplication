using System;
using System.Linq;
using System.Web;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Tests.Web.Builders.Model.TaskPlanner;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.TaskPlanner;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using static Inprotech.Web.Picklists.TaskPlannerSavedSearchPicklistController;

namespace Inprotech.Tests.Web.Picklists
{
    public class TaskPlannerSavedSearchPicklistControllerFacts
    {
        public class SearchMethod : FactBase
        {
            [Fact]
            public void SearchAndMatchNumberOfRecords()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);
                SetupQueryData(Db);
                var result = fixture.Subject.Search(null, "Test").Data.ToArray();
                Assert.Equal(2, result.Length);
                Assert.Equal("Test search 1", ((SavedSearchPicklistItem)result[0]).SearchName);
                Assert.Equal("Test search 2", ((SavedSearchPicklistItem)result[1]).SearchName);
            }

            [Fact]
            public void SearchWithEmptyResult()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);
                SetupQueryData(Db);
                var result = fixture.Subject.Search(null, "norecords").Data.ToArray();
                Assert.Equal(0, result.Length);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);
                SetupQueryData(Db);
                var qParams = new CommonQueryParameters { SortBy = "Description", SortDir = "asc", Skip = 1, Take = 1 };
                var result = fixture.Subject.Search(qParams);
                var queries = result.Data.ToArray();
                Assert.Equal(3, result.Pagination.Total);
                Assert.Single(queries);
                Assert.Equal("Search 1", ((SavedSearchPicklistItem)queries[0]).Description);
            }

            [Fact]
            public void VerifySearchWithPublicOnlySavedSearches()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);
                SetupQueryData(Db, true);
                var result = fixture.Subject.Search(null, string.Empty, true).Data.ToArray();
                Assert.Equal(2, result.Length);
                Assert.Equal("My Tasks", ((SavedSearchPicklistItem)result[0]).SearchName);
                Assert.Equal("Test search 1", ((SavedSearchPicklistItem)result[1]).SearchName);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldReturnNullException()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);
                Assert.ThrowsAsync<ArgumentNullException>(async () => await fixture.Subject.Update(0, null));
            }

            [Fact]
            public void ShouldReturnNullExceptionWhenRecordIsNotAvailable()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);
                var updateDetails = new SavedSearchPicklistItem
                {
                    Key = 1,
                    SearchName = "Test",
                    Description = "TestDescription"
                };
                Assert.ThrowsAsync<ArgumentNullException>(async () => await fixture.Subject.Update(1, updateDetails));
            }

            [Fact]
            public async void ShouldReturnSuccess()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);
                const QueryContext contextId = QueryContext.TaskPlanner;
                var query = new Query { ContextId = (int)contextId, Id = 1, Name = Fixture.String(), Description = Fixture.String()}.In(Db);

                var updateDetails = new SavedSearchPicklistItem
                {
                    Key = query.Id,
                    SearchName = query.Name,
                    Description = query.Description,
                    IsPublic = true
                };

                var updateResult = new
                {
                    Result = "success",
                    Key = query.Id
                };

                var result = await fixture.Subject.Update((short)query.Id, updateDetails);
                Assert.Equal(updateResult.Result, result.Result);
                Assert.Equal(updateResult.Key, result.Key);
            }

            [Fact]
            public async void ShouldReturnDoesNotHaveAccessToTask()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);
                const QueryContext contextId = QueryContext.TaskPlanner;
                var query = new Query { ContextId = (int)contextId, Id = 1, Name = Fixture.String(), Description = Fixture.String() }.In(Db);

                var updateDetails = new SavedSearchPicklistItem
                {
                    Key = query.Id,
                    SearchName = query.Name,
                    Description = query.Description,
                    IsPublic = true
                };
                fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);
                await Assert.ThrowsAsync<HttpException>(async () => await fixture.Subject.Update((short)query.Id, updateDetails));
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public async void ShouldGetCannotDeleteAsRestrictedByAdmin()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);

                var contextId = (int)QueryContext.TaskPlanner;
                var query = new QueryBuilder
                {
                    SearchName = "My Tasks",
                    Description = "My Tasks description",
                    ContextId = contextId
                }.Build().In(Db);

                var profile = new ProfileBuilder
                {
                    ProfileId = 1,
                    ProfileName = Fixture.String()
                }.Build().In(Db);
                new TaskPlannerTabsByProfileBuilder
                {
                    ProfileId = profile.Id,
                    QueryId = query.Id,
                    TabSequence = 1
                }.Build().In(Db);

                fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);
                var result = await fixture.Subject.Delete((short)query.Id);
                Assert.Equal(((ValidationError[])result.Errors)[0].Message, "taskPlanner.savedSearchRestrictedByAdmin");
            }

            [Fact]
            public async void ShouldGetCannotDeleteAsInUseError()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);

                var contextId = (int)QueryContext.TaskPlanner;
                var query = new QueryBuilder
                {
                    SearchName = "My Tasks",
                    Description = "My Tasks description",
                    ContextId = contextId
                }.Build().In(Db);

                var user = new UserBuilder(Db).Build().In(Db);
                new TaskPlannerTabsBuilder(Db).Build(query.Id, 1, user.Id).In(Db);
                fixture.SecurityContext.User.Returns(user);
                fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);
                var result = await fixture.Subject.Delete((short)query.Id);
                Assert.Equal(((ValidationError[])result.Errors)[0].Message, "taskPlanner.savedSearchIsInUse");
            }

            [Fact]
            public async void ShouldBeAbleToDelete()
            {
                var fixture = new TaskPlannerSavedSearchPicklistControllerFixture(Db);

                var contextId = (int)QueryContext.TaskPlanner;
                var query = new QueryBuilder
                {
                    SearchName = "My Tasks",
                    Description = "My Tasks description",
                    ContextId = contextId
                }.Build().In(Db);

                fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);
                var result = await fixture.Subject.Delete((short)query.Id);
                Assert.Equal(result.Result, "success");
            }
        }

        static void SetupQueryData(InMemoryDbContext db, bool createPrivateSearch = false)
        {
            var contextId = (int)QueryContext.TaskPlanner;
            new QueryBuilder { SearchName = "My Tasks", Description = "My Tasks description", ContextId = contextId }.Build().In(db);
            new QueryBuilder { SearchName = "Test search 1", Description = "Search 1", ContextId = contextId }.Build().In(db);
            new QueryBuilder { SearchName = "Test search 2", Description = "Search 2", ContextId = contextId, IdentityId = createPrivateSearch ? Fixture.Integer() : null }.Build().In(db);
            new QueryBuilder { SearchName = "Test case search ", Description = "Case Search", ContextId = (int)QueryContext.CaseSearch }.Build().In(db);
        }
    }

    public class TaskPlannerSavedSearchPicklistControllerFixture : IFixture<TaskPlannerSavedSearchPicklistController>
    {
        public TaskPlannerSavedSearchPicklistControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            SecurityContext = Substitute.For<ISecurityContext>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);
            SecurityContext.User.Returns(new User());
            TaskPlannerTabResolver = Substitute.For<ITaskPlannerTabResolver>();
            Subject = new TaskPlannerSavedSearchPicklistController(db, SecurityContext, PreferredCultureResolver, TaskSecurityProvider, TaskPlannerTabResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }

        public ISecurityContext SecurityContext { get; set; }
        public TaskPlannerSavedSearchPicklistController Subject { get; }

        public ITaskPlannerTabResolver TaskPlannerTabResolver { get; }
    }
}