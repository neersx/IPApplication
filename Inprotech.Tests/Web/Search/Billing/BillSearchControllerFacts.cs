using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Search;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Billing
{
    public class BillSearchControllerFacts : FactBase
    {
        public class RunSearchMethod
        {
            [Fact]
            public async Task ShouldThrowForbiddenExceptionIfWebPartSecurityNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    fixture.WebPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch).Returns(false);

                                                                                    await fixture.Subject.RunSearch(Arg.Any<SearchRequestParams<BillSearchRequestFilter>>());
                                                                                });

                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ShouldCallRunSearchMethodPassingSearchRequestParameter()
            {
                var filter = new SearchRequestParams<BillSearchRequestFilter> { QueryContext = QueryContext.BillingSelection };
                var fixture = new BillSearchControllerFixture();

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
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    await fixture.Subject.RunSearch(new SearchRequestParams<BillSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class SearchColumnsMethod
        {
            [Fact]
            public async Task ShouldThrowForbiddenExceptionIfWebPartSecurityNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    fixture.WebPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch).Returns(false);

                                                                                    await fixture.Subject.SearchColumns(Arg.Any<ColumnRequestParams>());
                                                                                });

                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ShouldCallGetSearchColumnsMethodPassingColumnRequestParameter()
            {
                var filter = new ColumnRequestParams
                {
                    QueryContext = QueryContext.BillingSelection,
                    PresentationType = Fixture.String(),
                    QueryKey = Fixture.Integer(),
                    SelectedColumns = new[]
                    {
                        new SelectedColumn(),
                        new SelectedColumn()
                    }
                };

                var fixture = new BillSearchControllerFixture();

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
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    await fixture.Subject.SearchColumns(new ColumnRequestParams());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunEditedSavedSearchMethod
        {
            [Fact]
            public async Task ShouldThrowForbiddenExceptionIfWebPartSecurityNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    fixture.WebPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch).Returns(false);

                                                                                    await fixture.Subject.RunEditedSavedSearch(Arg.Any<SavedSearchRequestParams<BillSearchRequestFilter>>());
                                                                                });

                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter()
            {
                var filter = new SavedSearchRequestParams<BillSearchRequestFilter> { QueryContext = QueryContext.BillingSelection };
                var fixture = new BillSearchControllerFixture();

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
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    await fixture.Subject.RunEditedSavedSearch(new SavedSearchRequestParams<BillSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class ExportMethod
        {
            [Fact]
            public async Task ShouldThrowForbiddenExceptionIfWebPartSecurityNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    fixture.WebPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch).Returns(false);

                                                                                    await fixture.Subject.Export(Arg.Any<SearchExportParams<BillSearchRequestFilter>>());
                                                                                });

                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ShouldCallExportMethodPassingSearchExportParameter()
            {
                var filter = new SearchExportParams<BillSearchRequestFilter> { QueryContext = QueryContext.BillingSelection };
                var fixture = new BillSearchControllerFixture();

                await fixture.Subject.Export(filter);

                fixture.SearchExportService.Received(1).Export(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public void ShouldCallExportMethodPassingDeselectedIds()
            {
                var fixture = new BillSearchControllerFixture();
                var deselectedIds = new[] { 1, 5, 6 };
                var filter = new SearchExportParams<BillSearchRequestFilter> { QueryContext = QueryContext.BillingSelection, DeselectedIds = deselectedIds, Criteria = new BillSearchRequestFilter() };

                fixture.Subject.Export(filter);

                var rowKeysFilter = filter.Criteria.SearchRequest.Single().RowKeys;
                Assert.Equal(string.Join(",", deselectedIds), rowKeysFilter.Value);
                Assert.Equal((short)CollectionExtensions.FilterOperator.NotIn, rowKeysFilter.Operator);
                fixture.SearchExportService.Received(1).Export(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    await fixture.Subject.Export(new SearchExportParams<BillSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class GetFilterDataForColumnMethod
        {
            [Fact]
            public async Task ShouldThrowForbiddenExceptionIfWebPartSecurityNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    fixture.WebPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch).Returns(false);

                                                                                    await fixture.Subject.GetFilterDataForColumn(Arg.Any<ColumnFilterParams<BillSearchRequestFilter>>());
                                                                                });

                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ShouldCallGetFilterDataForColumnMethodPassingColumnFilterParameter()
            {
                var filter = new ColumnFilterParams<BillSearchRequestFilter> { QueryContext = QueryContext.BillingSelection };
                var filterData = new[]
                {
                    new CodeDescription(),
                    new CodeDescription()
                };
                var fixture = new BillSearchControllerFixture();

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
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    await fixture.Subject.GetFilterDataForColumn(new ColumnFilterParams<BillSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunSavedSearchMethod
        {
            [Fact]
            public async Task ShouldThrowForbiddenExceptionIfWebPartSecurityNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    fixture.WebPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch).Returns(false);

                                                                                    await fixture.Subject.RunSavedSearch(Arg.Any<SavedSearchRequestParams<BillSearchRequestFilter>>());
                                                                                });

                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter()
            {
                var filter = new SavedSearchRequestParams<BillSearchRequestFilter> { QueryContext = QueryContext.BillingSelection };
                var fixture = new BillSearchControllerFixture();

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
                                                                                    var fixture = new BillSearchControllerFixture();
                                                                                    await fixture.Subject.RunSavedSearch(new SavedSearchRequestParams<BillSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }
    }

    public class BillSearchControllerFixture : IFixture<BillSearchController>
    {
        public BillSearchControllerFixture()
        {
            SearchService = Substitute.For<ISearchService>();
            SearchExportService = Substitute.For<ISearchExportService>();
            WebPartSecurity = Substitute.For<IWebPartSecurity>();
            WebPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch).Returns(true);
            Subject = new BillSearchController(SearchService, SearchExportService, WebPartSecurity);
        }

        public ISearchService SearchService { get; set; }
        public ISearchExportService SearchExportService { get; set; }

        public IWebPartSecurity WebPartSecurity { get; set; }

        public BillSearchController Subject { get; }
    }
}