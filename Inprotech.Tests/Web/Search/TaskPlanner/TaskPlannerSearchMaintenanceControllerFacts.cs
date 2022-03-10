using System;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using Inprotech.Web.Search.TaskPlanner;
using InprotechKaizen.Model.Components.Cases.Reminders.Search;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner
{
    public class TaskPlannerSearchMaintenanceControllerFacts
    {
        static TaskPlannerRequestFilter PrepareSearchFilter()
        {
            return new TaskPlannerRequestFilter
            {
                SearchRequest = new TaskPlannerRequest()
            };
        }

        public class AddMethod
        {
            [Fact]
            public void ExecutesTaskPlannerSavedSearchPassingParams()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                var req = new TaskPlannerRequestFilter
                {
                    SearchRequest = new TaskPlannerRequest()
                };
                var taskPlannerSavedSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>
                {
                    QueryContext = QueryContext.TaskPlanner,
                    SearchFilter = req
                };

                f.SavedSearchService.SaveSearch<TaskPlannerRequestFilter>(null).ReturnsForAnyArgs(new { Success = true });

                f.Subject.Add(taskPlannerSavedSearch);

                f.SavedSearchService.Received(1).SaveSearch(Arg.Any<FilteredSavedSearch<TaskPlannerRequestFilter>>());
            }

            [Fact]
            public void ThrowsExceptionIfFilterIsNull()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                var taskPlannerSavedSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.Add(taskPlannerSavedSearch); });
            }

            [Fact]
            public void ThrowsExceptionIfFilterArgumentIsNull()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.Add(null); });
            }

            [Fact]
            public void ThrowsExceptionIfIQueryContextIsDifferent()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();

                var taskPlannerSavedSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchFilter = PrepareSearchFilter()
                };
                var exception = Assert.Throws<HttpResponseException>(() => { f.Subject.Add(taskPlannerSavedSearch); });
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionIfItIsPublicSearchAndDoesNotHaveAccessToTask()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();

                var taskPlannerSavedSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>
                {
                    QueryContext = QueryContext.TaskPlanner,
                    IsPublic = true,
                    SearchFilter = new TaskPlannerRequestFilter()
                };

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);

                Assert.Throws<System.Web.HttpException>(() => { f.Subject.Add(taskPlannerSavedSearch); });
            }
        }

        public class GetMethod
        {
            [Fact]
            public void Get()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                var queryKey = 1;
                f.Subject.Get(queryKey);
                f.SavedSearchService.Received(1).Get(queryKey);
            }

            [Fact]
            public void ThrowsExceptionIfQueryKeyIsNull()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.Get(null); });
            }
        }

        public class UpdateMethod
        {
            [Fact]
            public void ThrowsExceptionIfFilterArgumentIsNull()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.Update(Fixture.Integer(), null); });
            }

            [Fact]
            public void ThrowsExceptionIfIQueryContextIsDifferent()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();

                var taskPlannerSavedSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchFilter = new TaskPlannerRequestFilter()
                };
                var exception = Assert.Throws<HttpResponseException>(() => { f.Subject.Update(Fixture.Integer(), taskPlannerSavedSearch); });
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public void ThrowsUnauthorizedAccessExceptionIfNotPublic()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                var taskPlannerSavedSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>
                {
                    QueryContext = QueryContext.TaskPlanner,
                    IsPublic = true,
                    SearchFilter = PrepareSearchFilter()
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);

                Assert.Throws<System.Web.HttpException>(() => { f.Subject.Update(Fixture.Integer(), taskPlannerSavedSearch); });
            }

            [Fact]
            public void Update()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();

                var taskPlannerSavedSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>
                {
                    QueryContext = QueryContext.TaskPlanner,
                    IsPublic = true,
                    SearchFilter = PrepareSearchFilter()
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);

                f.Subject.Update(1, taskPlannerSavedSearch);
                f.SavedSearchService.Received(1).Update(1, Arg.Any<FilteredSavedSearch<TaskPlannerRequestFilter>>());
            }

            [Fact]
            public void ThrowsUnauthorizedAccessExceptionIfNotPublicOnupdateDetails()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                var taskPlannerSavedSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>
                {
                    QueryContext = QueryContext.TaskPlanner,
                    IsPublic = true,
                    SearchFilter = PrepareSearchFilter()
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);

                Assert.Throws<System.Web.HttpException>(() => { f.Subject.UpdateDetails(Fixture.Integer(), taskPlannerSavedSearch); });
            }
        }

        public class DeleteSavedSearch
        {
            [Fact]
            public void ThrowsArgumentNullExceptionWhenQueryKeyIsNull()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.DeleteSavedSearch(null); });
            }

            [Fact]
            public void ShouldDeleteExistingSavedSearch()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);
                f.Subject.DeleteSavedSearch(1);
                f.SavedSearchService.Received(1).DeleteSavedSearch(1);
            }
        }

        public class SaveAsMethod
        {
            [Fact]
            public void ThrowsExceptionIfFilterArgumentIsNull()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.SaveAs(Fixture.Integer(), null); });
            }

            [Fact]
            public void ThrowsExceptionIfIQueryContextIsDifferent()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();

                var taskPlannerSavedSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchFilter = new TaskPlannerRequestFilter()
                };
                var exception = Assert.Throws<HttpResponseException>(() => { f.Subject.SaveAs(Fixture.Integer(), taskPlannerSavedSearch); });
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public void ExecutesSaveAs()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                var req = PrepareSearchFilter();
                var caseSaveAsSearch = new FilteredSavedSearch<TaskPlannerRequestFilter>
                {
                    QueryContext = QueryContext.TaskPlanner,
                    SearchFilter = req
                };

                f.SavedSearchService.SaveAsSearch<TaskPlannerRequestFilter>(4, null).ReturnsForAnyArgs(new { Success = true });
                f.Subject.SaveAs(4, caseSaveAsSearch);

                f.SavedSearchService.Received(1).SaveAsSearch(4, Arg.Any<FilteredSavedSearch<TaskPlannerRequestFilter>>());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSavedSearchIsNull()
            {
                var f = new TaskPlannerSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.SaveAs(Fixture.Integer(), null); });
            }
        }
    }

    public class TaskPlannerSearchMaintenanceControllerFixture : IFixture<TaskPlannerSearchMaintenanceController>
    {
        public TaskPlannerSearchMaintenanceControllerFixture()
        {
            SavedSearchService = Substitute.For<ISavedSearchService>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

            Subject = new TaskPlannerSearchMaintenanceController(SavedSearchService, TaskSecurityProvider);
        }

        public ISavedSearchService SavedSearchService { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public TaskPlannerSearchMaintenanceController Subject { get; }
    }
}