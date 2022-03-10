using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using Inprotech.Web.Search.PriorArt;
using InprotechKaizen.Model.Components.Cases.PriorArt.Search;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.PriorArt
{
    public class PriorArtSearchMaintenanceControllerFacts
    {
        static PriorArtSearchRequestFilter PrepareSearchFilter()
        {
            return new PriorArtSearchRequestFilter
            {
                SearchRequest = new[]
                {
                    new PriorArtSearchRequest()
                }
            };
        }

        public class AddMethod
        {
            [Fact]
            public void ExecutesNameSavedSearchPassingParams()
            {
                var f = new PriorArtSearchMaintenanceControllerFixture();
                var req = new PriorArtSearchRequestFilter
                {
                    SearchRequest = new[]
                    {
                        new PriorArtSearchRequest()
                    }
                };
                var savedSearch = new FilteredSavedSearch<PriorArtSearchRequestFilter>
                {
                    QueryContext = QueryContext.PriorArtSearch,
                    SearchFilter = req
                };

                f.SavedSearchService.SaveSearch<PriorArtSearchRequestFilter>(null).ReturnsForAnyArgs(new {Success = true});

                f.Subject.Add(savedSearch);

                f.SavedSearchService.Received(1).SaveSearch(Arg.Any<FilteredSavedSearch<PriorArtSearchRequestFilter>>());
            }

            [Fact]
            public void ThrowsExceptionIfFilterIsNull()
            {
                var f = new PriorArtSearchMaintenanceControllerFixture();

                var savedSearch = new FilteredSavedSearch<PriorArtSearchRequestFilter>();

                Assert.Throws<ArgumentNullException>(() => { f.Subject.Add(savedSearch); });
            }

            [Fact]
            public void ThrowsExceptionIfItIsPublicSearchAndDoesNotHaveAccessToTask()
            {
                var f = new PriorArtSearchMaintenanceControllerFixture();

                var savedSearch = new FilteredSavedSearch<PriorArtSearchRequestFilter>
                {
                    QueryContext = QueryContext.PriorArtSearch,
                    IsPublic = true,
                    SearchFilter = new PriorArtSearchRequestFilter()
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
                var f = new PriorArtSearchMaintenanceControllerFixture();
                var queryKey = 2;
                f.Subject.Get(queryKey);
                f.SavedSearchService.Received(1).Get(queryKey);
            }

            [Fact]
            public void ThrowsExceptionIfQueryKeyIsNull()
            {
                var f = new PriorArtSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.Get(null); });
            }
        }

        public class UpdateMethod
        {
            [Fact]
            public void ThrowsUnauthorizedAccessExceptionIfNotPublic()
            {
                var f = new PriorArtSearchMaintenanceControllerFixture();
                var savedSearch = new FilteredSavedSearch<PriorArtSearchRequestFilter>
                {
                    QueryContext = QueryContext.PriorArtSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);
                var queryKey = 2;

                Assert.Throws<UnauthorizedAccessException>(() => { f.Subject.UpdateDetails(queryKey, savedSearch); });
            }

            [Fact]
            public void Update()
            {
                var f = new PriorArtSearchMaintenanceControllerFixture();

                var savedSearch = new FilteredSavedSearch<PriorArtSearchRequestFilter>
                {
                    QueryContext = QueryContext.PriorArtSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);

                var req = PrepareSearchFilter();

                savedSearch.SearchFilter = req;
                var queryKey = 2;
                f.Subject.Update(queryKey, savedSearch);
                f.SavedSearchService.Received(1).Update(queryKey, Arg.Any<FilteredSavedSearch<PriorArtSearchRequestFilter>>());
            }

            [Fact]
            public void UpdateDetails()
            {
                var f = new PriorArtSearchMaintenanceControllerFixture();
                var savedSearch = new FilteredSavedSearch<PriorArtSearchRequestFilter>
                {
                    QueryContext = QueryContext.PriorArtSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);
                var queryKey = 2;
                var req = PrepareSearchFilter();
                savedSearch.SearchFilter = req;
                f.Subject.Update(queryKey, savedSearch);
                f.SavedSearchService.Received(1).Update(queryKey, Arg.Any<FilteredSavedSearch<PriorArtSearchRequestFilter>>());
            }
        }

        public class SaveAsMethod
        {
            [Fact]
            public void ExecutesSaveAs()
            {
                var f = new PriorArtSearchMaintenanceControllerFixture();
                var req = PrepareSearchFilter();
                var saveAsSearch = new FilteredSavedSearch<PriorArtSearchRequestFilter>
                {
                    QueryContext = QueryContext.PriorArtSearch,
                    SearchFilter = req
                };

                f.SavedSearchService.SaveAsSearch<PriorArtSearchRequestFilter>(4, null).ReturnsForAnyArgs(new {Success = true});
                f.Subject.SaveAs(4, saveAsSearch);

                f.SavedSearchService.Received(1).SaveAsSearch(4, Arg.Any<FilteredSavedSearch<PriorArtSearchRequestFilter>>());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSavedSearchIsNull()
            {
                var f = new PriorArtSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.SaveAs(Fixture.Integer(), null); });
            }
        }
    }

    public class PriorArtSearchMaintenanceControllerFixture : IFixture<PriorArtSearchMaintenanceController>
    {
        public PriorArtSearchMaintenanceControllerFixture()
        {
            SavedSearchService = Substitute.For<ISavedSearchService>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            Subject = new PriorArtSearchMaintenanceController(SavedSearchService, TaskSecurityProvider);
        }

        public ISavedSearchService SavedSearchService { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public PriorArtSearchMaintenanceController Subject { get; }
    }
}