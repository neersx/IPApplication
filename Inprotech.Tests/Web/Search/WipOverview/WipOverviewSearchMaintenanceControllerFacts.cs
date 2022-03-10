using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using Inprotech.Web.Search.WipOverview;
using InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.WipOverview
{
    public class WipOverviewSearchMaintenanceControllerFacts
    {
        static WipOverviewSearchRequestFilter PrepareSearchFilter()
        {
            return new WipOverviewSearchRequestFilter
            {
                SearchRequest = new[]
                {
                    new WipOverviewSearchRequest()
                }
            };
        }

        public class AddMethod
        {
            [Fact]
            public void ExecutesNameSavedSearchPassingParams()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();
                var req = new WipOverviewSearchRequestFilter
                {
                    SearchRequest = new[]
                    {
                        new WipOverviewSearchRequest()
                    }
                };
                var savedSearch = new FilteredSavedSearch<WipOverviewSearchRequestFilter>
                {
                    QueryContext = QueryContext.WipOverviewSearch,
                    SearchFilter = req
                };

                f.SavedSearchService.SaveSearch<WipOverviewSearchRequestFilter>(null).ReturnsForAnyArgs(new {Success = true});

                f.Subject.Add(savedSearch);

                f.SavedSearchService.Received(1).SaveSearch(Arg.Any<FilteredSavedSearch<WipOverviewSearchRequestFilter>>());
            }

            [Fact]
            public void ThrowsExceptionIfFilterIsNull()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();

                var savedSearch = new FilteredSavedSearch<WipOverviewSearchRequestFilter>();

                Assert.Throws<ArgumentNullException>(() => { f.Subject.Add(savedSearch); });
            }

            [Fact]
            public void ThrowsExceptionIfItIsPublicSearchAndDoesNotHaveAccessToTask()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();

                var savedSearch = new FilteredSavedSearch<WipOverviewSearchRequestFilter>
                {
                    QueryContext = QueryContext.WipOverviewSearch,
                    IsPublic = true,
                    SearchFilter = new WipOverviewSearchRequestFilter()
                };

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);

                Assert.Throws<UnauthorizedAccessException>(() => { f.Subject.Add(savedSearch); });
            }
        }

        public class GetMethod
        {
            [Fact]
            public void Get()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();
                var queryKey = 2;
                f.Subject.Get(queryKey);
                f.SavedSearchService.Received(1).Get(queryKey);
            }

            [Fact]
            public void ThrowsExceptionIfQueryKeyIsNull()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.Get(null); });
            }
        }

        public class UpdateMethod
        {
            [Fact]
            public void ThrowsUnauthorizedAccessExceptionIfNotPublic()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();
                var savedSearch = new FilteredSavedSearch<WipOverviewSearchRequestFilter>
                {
                    QueryContext = QueryContext.WipOverviewSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);
                var queryKey = 2;

                Assert.Throws<UnauthorizedAccessException>(() => { f.Subject.UpdateDetails(queryKey, savedSearch); });
            }

            [Fact]
            public void Update()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();

                var savedSearch = new FilteredSavedSearch<WipOverviewSearchRequestFilter>
                {
                    QueryContext = QueryContext.WipOverviewSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);

                var req = PrepareSearchFilter();

                savedSearch.SearchFilter = req;
                var queryKey = 2;
                f.Subject.Update(queryKey, savedSearch);
                f.SavedSearchService.Received(1).Update(queryKey, Arg.Any<FilteredSavedSearch<WipOverviewSearchRequestFilter>>());
            }

            [Fact]
            public void UpdateDetails()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();
                var savedSearch = new FilteredSavedSearch<WipOverviewSearchRequestFilter>
                {
                    QueryContext = QueryContext.WipOverviewSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);
                var queryKey = 2;
                var req = PrepareSearchFilter();
                savedSearch.SearchFilter = req;
                f.Subject.Update(queryKey, savedSearch);
                f.SavedSearchService.Received(1).Update(queryKey, Arg.Any<FilteredSavedSearch<WipOverviewSearchRequestFilter>>());
            }
        }

        public class SaveAsMethod
        {
            [Fact]
            public void ExecutesSaveAs()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();
                var req = PrepareSearchFilter();
                var saveAsSearch = new FilteredSavedSearch<WipOverviewSearchRequestFilter>
                {
                    QueryContext = QueryContext.WipOverviewSearch,
                    SearchFilter = req
                };

                f.SavedSearchService.SaveAsSearch<WipOverviewSearchRequestFilter>(4, null).ReturnsForAnyArgs(new {Success = true});
                f.Subject.SaveAs(4, saveAsSearch);

                f.SavedSearchService.Received(1).SaveAsSearch(4, Arg.Any<FilteredSavedSearch<WipOverviewSearchRequestFilter>>());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSavedSearchIsNull()
            {
                var f = new WipOverviewSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.SaveAs(Fixture.Integer(), null); });
            }
        }
    }

    public class WipOverviewSearchMaintenanceControllerFixture : IFixture<WipOverviewSearchMaintenanceController>
    {
        public WipOverviewSearchMaintenanceControllerFixture()
        {
            SavedSearchService = Substitute.For<ISavedSearchService>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            Subject = new WipOverviewSearchMaintenanceController(SavedSearchService, TaskSecurityProvider);
        }

        public ISavedSearchService SavedSearchService { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public WipOverviewSearchMaintenanceController Subject { get; }
    }
}