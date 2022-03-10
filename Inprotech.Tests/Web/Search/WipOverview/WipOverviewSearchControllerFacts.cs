using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Search;
using Inprotech.Web.Search.WipOverview;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search;
using InprotechKaizen.Model.Components.Search.WipOverview;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.WipOverview
{
    public class WipOverviewSearchControllerFacts
    {
        public class RunSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedWipOverviewSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<WipOverviewSearchController>("RunSearch", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallRunSearchMethodPassingSearchRequestParameter()
            {
                var filter = new SearchRequestParams<WipOverviewSearchRequestFilter> { QueryContext = QueryContext.WipOverviewSearch };
                var fixture = new WipOverviewSearchControllerFixture();

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
                                                                                    var fixture = new WipOverviewSearchControllerFixture();
                                                                                    await fixture.Subject.RunSearch(new SearchRequestParams<WipOverviewSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class SearchColumnsMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedWipOverviewSearch)]
            [InlineData(ApplicationTask.RunSavedWipOverviewSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<WipOverviewSearchController>("SearchColumns", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallGetSearchColumnsMethodPassingColumnRequestParameter()
            {
                var filter = new ColumnRequestParams
                {
                    QueryContext = QueryContext.WipOverviewSearch,
                    PresentationType = Fixture.String(),
                    QueryKey = Fixture.Integer(),
                    SelectedColumns = new[]
                    {
                        new SelectedColumn(),
                        new SelectedColumn()
                    }
                };

                var fixture = new WipOverviewSearchControllerFixture();

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
                                                                                    var fixture = new WipOverviewSearchControllerFixture();
                                                                                    await fixture.Subject.SearchColumns(new ColumnRequestParams());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunEditedSavedSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedWipOverviewSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<WipOverviewSearchController>("RunEditedSavedSearch", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter()
            {
                var filter = new SavedSearchRequestParams<WipOverviewSearchRequestFilter> { QueryContext = QueryContext.WipOverviewSearch };
                var fixture = new WipOverviewSearchControllerFixture();

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
                                                                                    var fixture = new WipOverviewSearchControllerFixture();
                                                                                    await fixture.Subject.RunEditedSavedSearch(new SavedSearchRequestParams<WipOverviewSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class ExportMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedWipOverviewSearch)]
            [InlineData(ApplicationTask.RunSavedWipOverviewSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<WipOverviewSearchController>("Export", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallExportMethodPassingSearchExportParameter()
            {
                var filter = new SearchExportParams<WipOverviewSearchRequestFilter> { QueryContext = QueryContext.WipOverviewSearch };
                var fixture = new WipOverviewSearchControllerFixture();

                await fixture.Subject.Export(filter);

                fixture.SearchExportService.Received(1).Export(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public void ShouldCallExportMethodPassingDeselectedIds()
            {
                var fixture = new WipOverviewSearchControllerFixture();
                var deselectedIds = new[] { 1, 5, 6 };
                var filter = new SearchExportParams<WipOverviewSearchRequestFilter> { QueryContext = QueryContext.WipOverviewSearch, DeselectedIds = deselectedIds, Criteria = new WipOverviewSearchRequestFilter() };

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
                                                                                    var fixture = new WipOverviewSearchControllerFixture();
                                                                                    await fixture.Subject.Export(new SearchExportParams<WipOverviewSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class GetFilterDataForColumnMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedWipOverviewSearch)]
            [InlineData(ApplicationTask.RunSavedWipOverviewSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<WipOverviewSearchController>("GetFilterDataForColumn", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallGetFilterDataForColumnMethodPassingColumnFilterParameter()
            {
                var filter = new ColumnFilterParams<WipOverviewSearchRequestFilter> { QueryContext = QueryContext.WipOverviewSearch };
                var filterData = new[]
                {
                    new CodeDescription(),
                    new CodeDescription()
                };
                var fixture = new WipOverviewSearchControllerFixture();

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
                                                                                    var fixture = new WipOverviewSearchControllerFixture();
                                                                                    await fixture.Subject.GetFilterDataForColumn(new ColumnFilterParams<WipOverviewSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunSavedSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedWipOverviewSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<WipOverviewSearchController>("RunSavedSearch", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter()
            {
                var filter = new SavedSearchRequestParams<WipOverviewSearchRequestFilter> { QueryContext = QueryContext.WipOverviewSearch };
                var fixture = new WipOverviewSearchControllerFixture();

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
                                                                                    var fixture = new WipOverviewSearchControllerFixture();
                                                                                    await fixture.Subject.RunSavedSearch(new SavedSearchRequestParams<WipOverviewSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class PrepareCreateSingleBillMethod
        {
            [Fact]
            public async Task ShouldReturnNoError()
            {
                var fixture = new WipOverviewSearchControllerFixture();
                fixture.CreateBillValidator.Validate(Arg.Any<List<CreateBillRequest>>(), CreateBillValidationType.SingleBill).Returns(new List<CreateBillValidationError>());

                var request = new[] { new CreateBillRequest { CaseKey = Fixture.Integer(), DebtorKey = Fixture.Integer() } };
                var r = await fixture.Subject.PrepareCreateSingleBill(request);

                Assert.False(r.Any());
                fixture.CreateBillValidator.Received(1).Validate(request, CreateBillValidationType.SingleBill)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowArgumentNullExceptionIfRequestNotProvided()
            {
                await Assert.ThrowsAsync<ArgumentNullException>(
                                                                async () =>
                                                                {
                                                                    var fixture = new WipOverviewSearchControllerFixture();
                                                                    await fixture.Subject.PrepareCreateSingleBill(null);
                                                                });
            }
        }
        
        public class IsEntityRestrictedByCurrencyMethod
        {
            [Fact]
            public async Task ShouldReturnTrue()
            {
                var fixture = new WipOverviewSearchControllerFixture();
                fixture.Entities.IsRestrictedByCurrency(Arg.Any<int>()).Returns(true);
                var entityId = Fixture.Integer();
                var r = await fixture.Subject.IsEntityRestrictedByCurrency(entityId);

                Assert.True(r);
                fixture.Entities.Received(1).IsRestrictedByCurrency(entityId)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }

    public class WipOverviewSearchControllerFixture : IFixture<WipOverviewSearchController>
    {
        public WipOverviewSearchControllerFixture()
        {
            SearchService = Substitute.For<ISearchService>();
            SearchExportService = Substitute.For<ISearchExportService>();
            Entities = Substitute.For<IEntities>();
            CreateBillValidator = Substitute.For<ICreateBillValidator>();

            Subject = new WipOverviewSearchController(SearchService, SearchExportService, CreateBillValidator, Entities);
        }

        public ISearchService SearchService { get; set; }
        public ISearchExportService SearchExportService { get; set; }

        public IEntities Entities { get; set; }
        public ICreateBillValidator CreateBillValidator { get; set; }
        public WipOverviewSearchController Subject { get; }
    }
}