using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using Inprotech.Web.Search.Export;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case
{
    public class CaseSearchControllerFacts
    {
        public class RunSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedCaseSearch)]
            [InlineData(ApplicationTask.QuickCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("RunSearch", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.CaseSearch, false)]
            [InlineData(QueryContext.CaseSearchExternal, true)]
            public async Task ShouldCallRunSearchMethodPassingSearchRequestParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new SearchRequestParams<CaseSearchRequestFilter> {QueryContext = queryContext};
                var fixture = new CaseSearchControllerFixture(userIsExternal);

                var searchResult = new SearchResult();
                fixture.SearchService.RunSearch(filter)
                       .Returns(searchResult);

                var r = await fixture.Subject.RunSearch(filter);

                Assert.Equal(searchResult, r);

                fixture.SearchService.Received(1)
                       .RunSearch(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new CaseSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.RunSearch(new SearchRequestParams<CaseSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class SearchColumnsMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedCaseSearch)]
            [InlineData(ApplicationTask.RunSavedCaseSearch)]
            [InlineData(ApplicationTask.QuickCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("SearchColumns", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.CaseSearch, false)]
            [InlineData(QueryContext.CaseSearchExternal, true)]
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

                var fixture = new CaseSearchControllerFixture(userIsExternal);

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
                                                                                    var fixture = new CaseSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.SearchColumns(new ColumnRequestParams());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunEditedSavedSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("RunEditedSavedSearch", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.CaseSearch, false)]
            [InlineData(QueryContext.CaseSearchExternal, true)]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new SavedSearchRequestParams<CaseSearchRequestFilter> {QueryContext = queryContext};
                var fixture = new CaseSearchControllerFixture(userIsExternal);

                var savedSearchResult = new SearchResult();
                fixture.SearchService.RunEditedSavedSearch(filter)
                       .Returns(savedSearchResult);

                var r = await fixture.Subject.RunEditedSavedSearch(filter);

                Assert.Equal(savedSearchResult, r);

                fixture.SearchService.Received(1)
                       .RunEditedSavedSearch(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new CaseSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.RunEditedSavedSearch(new SavedSearchRequestParams<CaseSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class DueDateSavedSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("DueDateSavedSearch", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.CaseSearch, false)]
            [InlineData(QueryContext.CaseSearchExternal, true)]
            public async Task ShouldCallDueDateSavedSearchMethodPassingSavedSearchRequestParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new SavedSearchRequestParams<CaseSearchRequestFilter>
                {
                    QueryContext = queryContext,
                    Criteria = new CaseSearchRequestFilter(),
                    Params = new CommonQueryParameters()
                };

                var fixture = new CaseSearchControllerFixture(userIsExternal);

                var savedSearchResult = new SearchResult();
                fixture.CaseSearchService
                       .GetDueDateOnlyCaseSearchResult(filter.QueryKey.GetValueOrDefault(), filter.Criteria, filter.Params)
                       .Returns(savedSearchResult);

                var r = await fixture.Subject.DueDateSavedSearch(filter);

                Assert.Equal(savedSearchResult, r);

                fixture.CaseSearchService
                       .Received(1)
                       .GetDueDateOnlyCaseSearchResult(filter.QueryKey.GetValueOrDefault(), filter.Criteria, filter.Params)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new CaseSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.DueDateSavedSearch(new SavedSearchRequestParams<CaseSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class DueDatePresentationMethod
        {
            [Theory]
            [InlineData(ApplicationTask.RunSavedCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("DueDatePresentation", taskPermissionRequired);
            }

            [Theory]
            [InlineData(true, false)]
            [InlineData(false, true)]
            public void ShouldReturnDueDatePresentationColumnAvailability(bool hasDueDatePresentation, bool hasAllDatePresentation)
            {
                var queryKey = Fixture.Integer();
                var importanceLevel = new[]
                {
                    new KeyValuePair<string, string>("1", "not important"),
                    new KeyValuePair<string, string>("9", "critical")
                };

                var fixture = new CaseSearchControllerFixture(false);

                fixture.CaseSearchService
                       .DueDatePresentationColumn(queryKey)
                       .Returns((hasDueDatePresentation, hasAllDatePresentation));

                fixture.CaseSearchService
                       .GetImportanceLevels()
                       .Returns(importanceLevel);

                var r = fixture.Subject.DueDatePresentation(queryKey);

                Assert.Equal(hasDueDatePresentation, r.HasDueDatePresentationColumn);
                Assert.Equal(hasAllDatePresentation, r.HasAllDatePresentationColumn);
                Assert.Equal(importanceLevel, r.ImportanceOptions);
            }

            [Fact]
            public void ShouldNotReturnImportanceOptionsIfDateColumnsNotAvailable()
            {
                var queryKey = Fixture.Integer();
                var importanceLevel = new[]
                {
                    new KeyValuePair<string, string>("1", "not important"),
                    new KeyValuePair<string, string>("9", "critical")
                };

                var fixture = new CaseSearchControllerFixture(false);

                fixture.CaseSearchService
                       .DueDatePresentationColumn(queryKey)
                       .Returns((false, false));

                fixture.CaseSearchService
                       .GetImportanceLevels()
                       .Returns(importanceLevel);

                var r = fixture.Subject.DueDatePresentation(queryKey);

                Assert.False(r.HasDueDatePresentationColumn);
                Assert.False(r.HasAllDatePresentationColumn);
                Assert.Null(r.ImportanceOptions);
            }
        }

        public class ExportMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedCaseSearch)]
            [InlineData(ApplicationTask.RunSavedCaseSearch)]
            [InlineData(ApplicationTask.QuickCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("Export", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.CaseSearch, false)]
            [InlineData(QueryContext.CaseSearchExternal, true)]
            public async Task ShouldCallExportMethodPassingSearchExportParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new SearchExportParams<CaseSearchRequestFilter> {QueryContext = queryContext};
                var fixture = new CaseSearchControllerFixture(userIsExternal);

                await fixture.Subject.Export(filter);

                fixture.SearchExportService.Received(1).Export(filter)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldIncludeTheDeselectedIdsIfDeselectedIdsAreProvided()
            {
                var request = new SearchExportParams<CaseSearchRequestFilter>
                {
                    DeselectedIds = new[] {1, 4},
                    QueryContext = QueryContext.CaseSearch,
                    Criteria = new CaseSearchRequestFilter()
                };
                var fixture = new CaseSearchControllerFixture(false);

                fixture.Subject.Export(request);

                Assert.NotNull(request.Criteria);
                Assert.Equal(1, request.Criteria.SearchRequest.Count());
                Assert.NotNull(request.Criteria.SearchRequest.First().CaseKeys);
                Assert.Equal("1,4", request.Criteria.SearchRequest.First().CaseKeys.Value);
                Assert.Equal(1, request.Criteria.SearchRequest.First().CaseKeys.Operator);
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new CaseSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.Export(new SearchExportParams<CaseSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ShouldUpdateTheExistingCaseKeysWithOneOperatorIfDeselectedIdsAreProvided()
            {
                var request = new SearchExportParams<CaseSearchRequestFilter>
                {
                    DeselectedIds = new[] {1, 4},
                    QueryContext = QueryContext.CaseSearch,
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new List<CaseSearchRequest>
                        {
                            new CaseSearchRequest
                            {
                                CaseKeys = new SearchElement
                                {
                                    Value = "5,6",
                                    Operator = 1
                                }
                            }
                        }
                    }
                };
                var fixture = new CaseSearchControllerFixture(false);

                await fixture.Subject.Export(request);

                Assert.NotNull(request.Criteria);
                Assert.Equal(1, request.Criteria.SearchRequest.Count());
                Assert.NotNull(request.Criteria.SearchRequest.First().CaseKeys);
                Assert.Equal("5,6,1,4", request.Criteria.SearchRequest.First().CaseKeys.Value);
                Assert.Equal(1, request.Criteria.SearchRequest.First().CaseKeys.Operator);
            }

            [Fact]
            public async Task ShouldUpdateTheExistingCaseKeysWithZeroOperatorIfDeselectedIdsAreProvided()
            {
                var request = new SearchExportParams<CaseSearchRequestFilter>
                {
                    DeselectedIds = new[] {1, 4},
                    QueryContext = QueryContext.CaseSearch,
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new List<CaseSearchRequest>
                        {
                            new CaseSearchRequest
                            {
                                CaseKeys = new SearchElement
                                {
                                    Value = " 1, 2, 3, 4",
                                    Operator = 0
                                }
                            }
                        }
                    }
                };
                var fixture = new CaseSearchControllerFixture(false);

                await fixture.Subject.Export(request);

                Assert.NotNull(request.Criteria);
                Assert.Equal(1, request.Criteria.SearchRequest.Count());
                Assert.NotNull(request.Criteria.SearchRequest.First().CaseKeys);
                Assert.Equal("2,3", request.Criteria.SearchRequest.First().CaseKeys.Value);
                Assert.Equal(0, request.Criteria.SearchRequest.First().CaseKeys.Operator);
            }
        }

        public class GetFilterDataForColumnMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedCaseSearch)]
            [InlineData(ApplicationTask.RunSavedCaseSearch)]
            [InlineData(ApplicationTask.QuickCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("GetFilterDataForColumn", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.CaseSearch, false)]
            [InlineData(QueryContext.CaseSearchExternal, true)]
            public async Task ShouldCallGetFilterDataForColumnMethodPassingColumnFilterParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new ColumnFilterParams<CaseSearchRequestFilter> {QueryContext = queryContext};
                var filterData = new[]
                {
                    new CodeDescription(),
                    new CodeDescription()
                };
                var fixture = new CaseSearchControllerFixture(userIsExternal);

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
                                                                                    var fixture = new CaseSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.GetFilterDataForColumn(new ColumnFilterParams<CaseSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class RunSavedSearchMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("RunSavedSearch", taskPermissionRequired);
            }

            [Theory]
            [InlineData(QueryContext.CaseSearch, false)]
            [InlineData(QueryContext.CaseSearchExternal, true)]
            public async Task ShouldCallRunEditedSearchMethodPassingSavedSearchRequestParameter(QueryContext queryContext, bool userIsExternal)
            {
                var filter = new SavedSearchRequestParams<CaseSearchRequestFilter> {QueryContext = queryContext};
                var fixture = new CaseSearchControllerFixture(userIsExternal);

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
                                                                                    var fixture = new CaseSearchControllerFixture(Fixture.Boolean());
                                                                                    await fixture.Subject.RunSavedSearch(new SavedSearchRequestParams<CaseSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class ExportToCpaXmlMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("ExportToCpaXml", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldExecutesExportCpaXmlPassingParams()
            {
                var f = new CaseSearchControllerFixture(false);
                const string caseIds = "1,2,3";

                var filter = new SearchExportParams<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new[]
                        {
                            new CaseSearchRequest
                            {
                                CaseKeys = new SearchElement {Value = caseIds}
                            }
                        }
                    },
                    Params = new CommonQueryParameters()
                };
                var cpaXmlResult = new CpaXmlResult();

                f.CpaXmlExporter.ScheduleCpaXmlImport(caseIds).ReturnsForAnyArgs(cpaXmlResult);

                var r = await f.Subject.ExportToCpaXml(filter);

                Assert.Equal(cpaXmlResult, r);
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new CaseSearchControllerFixture(false);
                                                                                    await fixture.Subject.ExportToCpaXml(new SearchExportParams<CaseSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class CaseIdsForBulkOperationsMethod
        {
            [Theory]
            [InlineData(ApplicationTask.AdvancedCaseSearch)]
            [InlineData(ApplicationTask.QuickCaseSearch)]
            [InlineData(ApplicationTask.RunSavedCaseSearch)]
            public void ShouldSecureEndpointWithTaskSecurity(ApplicationTask taskPermissionRequired)
            {
                TaskSecurity.Secures<CaseSearchController>("CaseIdsForBulkOperations", taskPermissionRequired);
            }

            [Fact]
            public async Task ShouldExecutesMethodPassingParams()
            {
                var f = new CaseSearchControllerFixture(false);
                const string caseIds = "1,2,3";

                var filter = new SearchExportParams<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new[]
                        {
                            new CaseSearchRequest
                            {
                                CaseKeys = new SearchElement {Value = caseIds}
                            }
                        }
                    },
                    Params = new CommonQueryParameters()
                };
                var caseKeys = new List<int> {1, 2};

                f.CaseSearchService.DistinctCaseIdsForBulkOperations(filter).ReturnsForAnyArgs(caseKeys);

                var r = await f.Subject.CaseIdsForBulkOperations(filter);

                Assert.Equal(caseKeys, r);
            }

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new CaseSearchControllerFixture(false);
                                                                                    await fixture.Subject.CaseIdsForBulkOperations(new SearchExportParams<CaseSearchRequestFilter>());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }
    }

    public class CaseSearchControllerFixture : IFixture<CaseSearchController>
    {
        public CaseSearchControllerFixture(bool withExternalUser)
        {
            SearchService = Substitute.For<ISearchService>();
            CaseSearchService = Substitute.For<ICaseSearchService>();
            SearchExportService = Substitute.For<ISearchExportService>();
            CpaXmlExporter = Substitute.For<ICpaXmlExporter>();
            SecurityContext = Substitute.For<ISecurityContext>();

            SecurityContext.User.Returns(new User("user", withExternalUser));
            Subject = new CaseSearchController(SecurityContext, SearchService, CaseSearchService, SearchExportService, CpaXmlExporter);
        }

        public ISecurityContext SecurityContext { get; set; }
        public ISearchService SearchService { get; set; }
        public ICaseSearchService CaseSearchService { get; set; }
        public ISearchExportService SearchExportService { get; set; }
        public ICpaXmlExporter CpaXmlExporter { get; set; }
        public CaseSearchController Subject { get; }
    }
}