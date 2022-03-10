using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Search;
using Inprotech.Web.Search.PriorArt;
using InprotechKaizen.Model.Components.Cases.PriorArt.Search;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.PriorArt
{
    public class PriorArtSearchControllerFacts
    {
        public class RunSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedPriorArtSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<PriorArtSearchController>("RunSearch", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallRunSearchMethodPassingSearchRequestParameter()
            {
                var filter = new SearchRequestParams<PriorArtSearchRequestFilter> {QueryContext = QueryContext.PriorArtSearch};
                var fixture = new PriorArtSearchControllerFixture();

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
                                                                                    var fixture = new PriorArtSearchControllerFixture();
                                                                                    await fixture.Subject.RunSearch(new SearchRequestParams<PriorArtSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class SearchColumnsMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedPriorArtSearch)]
            [InlineData(ApplicationTask.RunSavedPriorArtSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<PriorArtSearchController>("SearchColumns", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallGetSearchColumnsMethodPassingColumnRequestParameter()
            {
                var filter = new ColumnRequestParams
                {
                    QueryContext = QueryContext.PriorArtSearch,
                    PresentationType = Fixture.String(),
                    QueryKey = Fixture.Integer(),
                    SelectedColumns = new[]
                    {
                        new SelectedColumn(),
                        new SelectedColumn()
                    }
                };

                var fixture = new PriorArtSearchControllerFixture();

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
                                                                                    var fixture = new PriorArtSearchControllerFixture();
                                                                                    await fixture.Subject.SearchColumns(new ColumnRequestParams());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunEditedSavedSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedPriorArtSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<PriorArtSearchController>("RunEditedSavedSearch", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter()
            {
                var filter = new SavedSearchRequestParams<PriorArtSearchRequestFilter> {QueryContext = QueryContext.PriorArtSearch};
                var fixture = new PriorArtSearchControllerFixture();

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
                                                                                    var fixture = new PriorArtSearchControllerFixture();
                                                                                    await fixture.Subject.RunEditedSavedSearch(new SavedSearchRequestParams<PriorArtSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class ExportMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedPriorArtSearch)]
            [InlineData(ApplicationTask.RunSavedPriorArtSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<PriorArtSearchController>("Export", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallExportMethodPassingSearchExportParameter()
            {
                var filter = new SearchExportParams<PriorArtSearchRequestFilter> {QueryContext = QueryContext.PriorArtSearch};
                var fixture = new PriorArtSearchControllerFixture();

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
                                                                                    var fixture = new PriorArtSearchControllerFixture();
                                                                                    await fixture.Subject.Export(new SearchExportParams<PriorArtSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ShouldSetTheDeselectedIdsWithProperOperator()
            {
                var filter = new SearchExportParams<PriorArtSearchRequestFilter>
                {
                    QueryContext = QueryContext.PriorArtSearch,
                    DeselectedIds = new [] { 3, 4 },
                    Criteria = new PriorArtSearchRequestFilter
                    {
                        SearchRequest = new []
                        {
                            new PriorArtSearchRequest()
                        }
                    }
                };
                var fixture = new PriorArtSearchControllerFixture();

                await fixture.Subject.Export(filter);
                var priorArtElement = filter.Criteria.SearchRequest.First();
                Assert.NotNull(priorArtElement);
                Assert.Equal("3,4", priorArtElement.PriorArtKeys.Value);
                Assert.Equal(1, priorArtElement.PriorArtKeys.Operator);
            }
        }

        public class GetFilterDataForColumnMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedPriorArtSearch)]
            [InlineData(ApplicationTask.RunSavedPriorArtSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<PriorArtSearchController>("GetFilterDataForColumn", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallGetFilterDataForColumnMethodPassingColumnFilterParameter()
            {
                var filter = new ColumnFilterParams<PriorArtSearchRequestFilter> {QueryContext = QueryContext.PriorArtSearch};
                var filterData = new[]
                {
                    new CodeDescription(),
                    new CodeDescription()
                };
                var fixture = new PriorArtSearchControllerFixture();

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
                                                                                    var fixture = new PriorArtSearchControllerFixture();
                                                                                    await fixture.Subject.GetFilterDataForColumn(new ColumnFilterParams<PriorArtSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunSavedSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedPriorArtSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<PriorArtSearchController>("RunSavedSearch", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter()
            {
                var filter = new SavedSearchRequestParams<PriorArtSearchRequestFilter> {QueryContext = QueryContext.PriorArtSearch};
                var fixture = new PriorArtSearchControllerFixture();

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
                                                                                    var fixture = new PriorArtSearchControllerFixture();
                                                                                    await fixture.Subject.RunSavedSearch(new SavedSearchRequestParams<PriorArtSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }
    }

    public class PriorArtSearchControllerFixture : IFixture<PriorArtSearchController>
    {
        public PriorArtSearchControllerFixture()
        {
            SearchService = Substitute.For<ISearchService>();
            SearchExportService = Substitute.For<ISearchExportService>();

            Subject = new PriorArtSearchController(SearchService, SearchExportService);
        }

        public ISearchService SearchService { get; set; }
        public ISearchExportService SearchExportService { get; set; }
        public PriorArtSearchController Subject { get; }
    }
}