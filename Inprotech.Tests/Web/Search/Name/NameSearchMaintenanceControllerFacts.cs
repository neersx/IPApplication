using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Name;
using InprotechKaizen.Model.Components.Names.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Name
{
    public class NameSearchMaintenanceControllerFacts
    {
        static NameSearchRequestFilter<NameSearchRequest> PrepareSearchFilter()
        {
            return new NameSearchRequestFilter<NameSearchRequest>
            {
                SearchRequest = new[]
                {
                    new NameSearchRequest
                    {
                        AnySearch = new SearchElement
                        {
                            Operator = 1, Value = "ABC"
                        }
                    }
                }
            };
        }

        public class AddMethod
        {
            [Fact]
            public void ExecutesNameSavedSearchPassingParams()
            {
                var f = new NameSearchMaintenanceControllerFixture();
                var req = new NameSearchRequestFilter<NameSearchRequest>
                {
                    SearchRequest = new[]
                    {
                        new NameSearchRequest {AnySearch = new SearchElement {Value = "abc", Operator = 1}}
                    }
                };
                var nameSavedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchFilter = req
                };

                f.SavedSearchService.SaveSearch<NameSearchRequestFilter<NameSearchRequest>>(null).ReturnsForAnyArgs(new {Success = true});

                f.Subject.Add(nameSavedSearch);

                f.SavedSearchService.Received(1).SaveSearch(Arg.Any<FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>>());
            }

            [Fact]
            public void ThrowsExceptionIfFilterIsNull()
            {
                var f = new NameSearchMaintenanceControllerFixture();

                var nameSavedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>();

                Assert.Throws<ArgumentNullException>(() => { f.Subject.Add(nameSavedSearch); });
            }

            [Fact]
            public void ThrowsExceptionIfItIsPublicSearchAndDoesNotHaveAccessToTask()
            {
                var f = new NameSearchMaintenanceControllerFixture();

                var nameSavedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    IsPublic = true,
                    SearchFilter = new NameSearchRequestFilter<NameSearchRequest>()
                };

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);

                Assert.Throws<UnauthorizedAccessException>(() => { f.Subject.Add(nameSavedSearch); });
            }
        }

        public class GetMethod
        {
            [Fact]
            public void Get()
            {
                var f = new NameSearchMaintenanceControllerFixture();
                var queryKey = 2;
                f.Subject.Get(queryKey);
                f.SavedSearchService.Received(1).Get(queryKey);
            }

            [Fact]
            public void ThrowsExceptionIfQueryKeyIsNull()
            {
                var f = new NameSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.Get(null); });
            }
        }

        public class UpdateMethod
        {
            [Fact]
            public void ThrowsUnauthorizedAccessExceptionIfNotPublic()
            {
                var f = new NameSearchMaintenanceControllerFixture();
                var nameSavedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(false);
                var queryKey = 2;

                Assert.Throws<UnauthorizedAccessException>(() => { f.Subject.UpdateDetails(queryKey, nameSavedSearch); });
            }

            [Fact]
            public void Update()
            {
                var f = new NameSearchMaintenanceControllerFixture();

                var nameSavedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);

                var req = PrepareSearchFilter();

                nameSavedSearch.SearchFilter = req;
                var queryKey = 2;
                f.Subject.Update(queryKey, nameSavedSearch);
                f.SavedSearchService.Received(1).Update(queryKey, Arg.Any<FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>>());
            }

            [Fact]
            public void UpdateDetails()
            {
                var f = new NameSearchMaintenanceControllerFixture();
                var nameSavedSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    IsPublic = true
                };
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch).Returns(true);
                var queryKey = 2;
                var req = PrepareSearchFilter();
                nameSavedSearch.SearchFilter = req;
                f.Subject.Update(queryKey, nameSavedSearch);
                f.SavedSearchService.Received(1).Update(queryKey, Arg.Any<FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>>());
            }
        }

        public class SaveAsMethod
        {
            [Fact]
            public void ExecutesSaveAs()
            {
                var f = new NameSearchMaintenanceControllerFixture();
                var req = PrepareSearchFilter();
                var caseSaveAsSearch = new FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>
                {
                    QueryContext = QueryContext.NameSearch,
                    SearchFilter = req
                };

                f.SavedSearchService.SaveAsSearch<NameSearchRequestFilter<NameSearchRequest>>(4, null).ReturnsForAnyArgs(new {Success = true});
                f.Subject.SaveAs(4, caseSaveAsSearch);

                f.SavedSearchService.Received(1).SaveAsSearch(4, Arg.Any<FilteredSavedSearch<NameSearchRequestFilter<NameSearchRequest>>>());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSavedSearchIsNull()
            {
                var f = new NameSearchMaintenanceControllerFixture();
                Assert.Throws<ArgumentNullException>(() => { f.Subject.SaveAs(Fixture.Integer(), null); });
            }
        }
    }

    public class NameSearchMaintenanceControllerFixture : IFixture<NameSearchMaintenanceController>
    {
        public NameSearchMaintenanceControllerFixture()
        {
            SavedSearchService = Substitute.For<ISavedSearchService>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User());

            Subject = new NameSearchMaintenanceController(securityContext, SavedSearchService, TaskSecurityProvider);
        }

        public ISavedSearchService SavedSearchService { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public NameSearchMaintenanceController Subject { get; }
    }
}