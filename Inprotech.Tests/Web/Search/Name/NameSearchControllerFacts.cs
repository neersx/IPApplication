using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Name;
using InprotechKaizen.Model.Components.Names.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;

namespace Inprotech.Tests.Web.Search.Name
{
    public class NameSearchControllerFacts
    {
        public class RunSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedNameSearch)]
            [InlineData(ApplicationTask.QuickNameSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<NameSearchController>("RunSearch", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.NameSearch, false)]
            [InlineData(QueryContext.NameSearchExternal, true)]
            public async Task ShouldCallRunSearchMethodPassingSearchRequestParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new SearchRequestParams<NameSearchRequestFilter<NameSearchRequest>> { QueryContext = queryContext };
                var fixture = new NameSearchControllerFixture(userIsExternal);

                var searchResult = new SearchResult();
                fixture.SearchService.RunSearch(filter)
                       .Returns(searchResult);

                var r = await fixture.Subject.RunSearch(filter);

                Assert.Equal(searchResult, r);

                fixture.SearchService.Received(1).RunSearch(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new NameSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.RunSearch(new SearchRequestParams<NameSearchRequestFilter<NameSearchRequest>>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class SearchColumnsMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedNameSearch)]
            [InlineData(ApplicationTask.RunSavedNameSearch)]
            [InlineData(ApplicationTask.QuickNameSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<NameSearchController>("SearchColumns", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.NameSearch, false)]
            [InlineData(QueryContext.NameSearchExternal, true)]
            public async Task ShouldCallGetSearchColumnsMethodPassingColumnRequestParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new ColumnRequestParams
                {
                    QueryContext = queryContext,
                    PresentationType = Fixture.String(),
                    QueryKey = Fixture.Integer(),
                    SelectedColumns = new[]
                    {
                        new SelectedColumn(),
                        new SelectedColumn()
                    }
                };

                var fixture = new NameSearchControllerFixture(userIsExternal);

                var searchColumns = new[]
                {
                    new SearchResult.Column(),
                    new SearchResult.Column()
                };

                fixture.SearchService
                       .GetSearchColumns(filter.QueryContext, filter.QueryKey, filter.SelectedColumns, filter.PresentationType)
                       .Returns(searchColumns);

                var r = await fixture.Subject.SearchColumns(filter);

                Assert.Equal(searchColumns, r);

                fixture.SearchService
                       .Received(1)
                       .GetSearchColumns(filter.QueryContext, filter.QueryKey, filter.SelectedColumns, filter.PresentationType)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new NameSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.SearchColumns(new ColumnRequestParams());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunEditedSavedSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedNameSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<NameSearchController>("RunEditedSavedSearch", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.NameSearch, false)]
            [InlineData(QueryContext.NameSearchExternal, true)]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new SavedSearchRequestParams<NameSearchRequestFilter<NameSearchRequest>> { QueryContext = queryContext };
                var fixture = new NameSearchControllerFixture(userIsExternal);

                var savedSearchResult = new SearchResult();
                fixture.SearchService.RunEditedSavedSearch(filter)
                       .Returns(savedSearchResult);

                var r = await fixture.Subject.RunEditedSavedSearch(filter);

                Assert.Equal(savedSearchResult, r);

                fixture.SearchService.Received(1).RunEditedSavedSearch(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new NameSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.RunEditedSavedSearch(new SavedSearchRequestParams<NameSearchRequestFilter<NameSearchRequest>>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class ExportMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedNameSearch)]
            [InlineData(ApplicationTask.RunSavedNameSearch)]
            [InlineData(ApplicationTask.QuickNameSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<NameSearchController>("Export", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.NameSearch, false)]
            [InlineData(QueryContext.NameSearchExternal, true)]
            public async Task ShouldCallExportMethodPassingSearchExportParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new SearchExportParams<NameSearchRequestFilter<NameSearchRequest>> { QueryContext = queryContext };
                var fixture = new NameSearchControllerFixture(userIsExternal);

                await fixture.Subject.Export(filter);

                fixture.SearchExportService.Received(1).Export(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new NameSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.Export(new SearchExportParams<NameSearchRequestFilter<NameSearchRequest>>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class GetFilterDataForColumnMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedNameSearch)]
            [InlineData(ApplicationTask.RunSavedNameSearch)]
            [InlineData(ApplicationTask.QuickNameSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<NameSearchController>("GetFilterDataForColumn", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.NameSearch, false)]
            [InlineData(QueryContext.NameSearchExternal, true)]
            public async Task ShouldCallGetFilterDataForColumnMethodPassingColumnFilterParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new ColumnFilterParams<NameSearchRequestFilter<NameSearchRequest>> { QueryContext = queryContext };
                var filterData = new[]
                {
                    new CodeDescription(),
                    new CodeDescription()
                };
                var fixture = new NameSearchControllerFixture(userIsExternal);

                fixture.SearchService.GetFilterDataForColumn(filter)
                       .Returns(filterData);

                var r = await fixture.Subject.GetFilterDataForColumn(filter);

                fixture.SearchService.Received(1).GetFilterDataForColumn(filter)
                       .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(filterData, r);
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new NameSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.GetFilterDataForColumn(new ColumnFilterParams<NameSearchRequestFilter<NameSearchRequest>>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunSavedSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedNameSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<NameSearchController>("RunSavedSearch", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.NameSearch, false)]
            [InlineData(QueryContext.NameSearchExternal, true)]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new SavedSearchRequestParams<NameSearchRequestFilter<NameSearchRequest>> { QueryContext = queryContext };
                var fixture = new NameSearchControllerFixture(userIsExternal);

                var savedSearchResult = new SearchResult();
                fixture.SearchService.RunSavedSearch(filter)
                       .Returns(savedSearchResult);

                var r = await fixture.Subject.RunSavedSearch(filter);

                Assert.Equal(savedSearchResult, r);

                fixture.SearchService.Received(1).RunSavedSearch(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new NameSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.RunSavedSearch(new SavedSearchRequestParams<NameSearchRequestFilter<NameSearchRequest>>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }
    }

    public class NameSearchControllerFixture : IFixture<NameSearchController>
    {
        public NameSearchControllerFixture(bool withExternalUser)
        {
            SearchService = Substitute.For<ISearchService>();
            SearchExportService = Substitute.For<ISearchExportService>();

            SecurityContext = Substitute.For<ISecurityContext>();
            NameSearchService = Substitute.For<INameSearchService>();
            SecurityContext.User.Returns(new User("user", withExternalUser));

            Subject = new NameSearchController(SecurityContext, SearchService, SearchExportService, NameSearchService);
        }

        public ISecurityContext SecurityContext { get; set; }
        public ISearchService SearchService { get; set; }
        public ISearchExportService SearchExportService { get; set; }
        public INameSearchService NameSearchService { get; set; }
        public NameSearchController Subject { get; }
    }
}