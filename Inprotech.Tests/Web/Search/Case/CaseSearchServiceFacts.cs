using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case
{
    public class CaseSearchServiceFacts : FactBase
    {
        public class GetImportanceLevelMethod : FactBase
        {
            [Fact]
            public void ShouldIgnoreNonNumericLevels()
            {
                new Importance { Description = "alpha", Level = "8a" }.In(Db);
                new Importance { Description = "maximum", Level = "9" }.In(Db);

                var fixture = new CaseSearchServiceFixture(Db);
                fixture.ImportanceLevelResolver.Resolve().Returns(5);

                var r = fixture.Subject.GetImportanceLevels().ToArray();

                Assert.Single(r);
                Assert.Equal("9", r.Single().Key);
            }

            [Fact]
            public void ShouldReturnImportanceLevelGreaterOrEqualToDefaultImportanceLevelForExternalUser()
            {
                new Importance { Description = "minimum", Level = "1" }.In(Db);
                new Importance { Description = "maximum", Level = "9" }.In(Db);

                var fixture = new CaseSearchServiceFixture(Db, true);
                fixture.ImportanceLevelResolver.Resolve().Returns(9);

                var r = fixture.Subject.GetImportanceLevels().ToArray();

                Assert.Single(r);
                Assert.Equal("9", r.Single().Key);
            }
            
            [Fact]
            public void ShouldReturnAllTheImportanceLevelForInternalUser()
            {
                new Importance { Description = "minimum", Level = "1" }.In(Db);
                new Importance { Description = "maximum", Level = "9" }.In(Db);

                var fixture = new CaseSearchServiceFixture(Db);
                var r = fixture.Subject.GetImportanceLevels().ToArray();
                Assert.Equal(2, r.Length);
            }
        }

        public class GlobalCaseChangeResultsMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnGlobalCaseChangeResult()
            {
                var globalProcessKey = Fixture.Integer();
                var presentationType = Fixture.String();
                var presentation = new SearchPresentation();
                var searchResult = new SearchResult();
                var parameters = new CommonQueryParameters();

                var fixture = new CaseSearchServiceFixture(Db);
                fixture.SearchPresentationService.GetSearchPresentation(QueryContext.CaseSearch, presentationType: presentationType)
                       .Returns(presentation);

                fixture.Search.GetFormattedSearchResults<CaseSearchRequestFilter>(null, presentation, parameters)
                       .Returns(searchResult);

                var r = await fixture.Subject.GlobalCaseChangeResults(parameters, globalProcessKey, presentationType);

                Assert.Equal(searchResult, r);

                var xmlFilterCriteria = "<Search><Filtering>" +
                                        "<csw_ListCase><FilterCriteriaGroup><FilterCriteria><GlobalProcessKey>" + globalProcessKey +
                                        "</GlobalProcessKey></FilterCriteria></FilterCriteriaGroup></csw_ListCase>" +
                                        "</Filtering></Search>";

                fixture.Search
                       .Received(1)
                       .GetFormattedSearchResults<CaseSearchRequestFilter>(null,
                                                                           Arg.Is<SearchPresentation>(_ => _.XmlCriteria == xmlFilterCriteria),
                                                                           parameters)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GlobalCaseChangeResultsExportDataMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnGlobalCaseChangeResultForExport()
            {
                var globalProcessKey = Fixture.Integer();
                var presentationType = Fixture.String();
                var searchExportResult = new SearchExportData
                {
                    SearchResults = new InprotechKaizen.Model.Components.Queries.SearchResults(),
                    Presentation = new SearchPresentation()
                };
                var parameters = new CommonQueryParameters();

                var fixture = new CaseSearchServiceFixture(Db);
                fixture.SearchPresentationService.GetSearchPresentation(QueryContext.CaseSearch, presentationType: presentationType)
                       .Returns(searchExportResult.Presentation);

                fixture.Search.GetSearchResults<CaseSearchRequestFilter>(null, searchExportResult.Presentation, parameters)
                       .Returns(searchExportResult.SearchResults);

                var r = await fixture.Subject.GlobalCaseChangeResultsExportData(parameters, globalProcessKey, presentationType);

                Assert.Equal(searchExportResult.SearchResults, r.SearchResults);
                Assert.Equal(searchExportResult.Presentation, r.Presentation);

                var xmlFilterCriteria = "<Search><Filtering>" +
                                        "<csw_ListCase><FilterCriteriaGroup><FilterCriteria><GlobalProcessKey>" + globalProcessKey +
                                        "</GlobalProcessKey></FilterCriteria></FilterCriteriaGroup></csw_ListCase>" +
                                        "</Filtering></Search>";

                fixture.Search
                       .Received(1)
                       .GetSearchResults<CaseSearchRequestFilter>(null,
                                                                  Arg.Is<SearchPresentation>(_ => _.XmlCriteria == xmlFilterCriteria),
                                                                  parameters)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GetRecentCaseSearchResultMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnRecentCasesForExternalUser()
            {
                const int defaultExternalCaseSearchQuery = -1;
                var parameters = new CommonQueryParameters();
                var searchResult = new SearchResult();
                var presentation = new SearchPresentation();

                var fixture = new CaseSearchServiceFixture(Db, true);

                fixture.SearchPresentationService
                       .GetSearchPresentation(QueryContext.CaseSearchExternal, defaultExternalCaseSearchQuery)
                       .Returns(presentation);

                fixture.Search
                       .GetFormattedSearchResults<CaseSearchRequestFilter>(null, presentation, parameters)
                       .Returns(searchResult);

                var r = await fixture.Subject.GetRecentCaseSearchResult(parameters);

                Assert.Equal(searchResult, r);
            }

            [Fact]
            public async Task ShouldReturnRecentCasesForInternalUser()
            {
                const int defaultInternalCaseSearchQuery = -2;
                var parameters = new CommonQueryParameters();
                var searchResult = new SearchResult();
                var presentation = new SearchPresentation();

                var fixture = new CaseSearchServiceFixture(Db);

                fixture.SearchPresentationService
                       .GetSearchPresentation(QueryContext.CaseSearch, defaultInternalCaseSearchQuery)
                       .Returns(presentation);

                fixture.Search
                       .GetFormattedSearchResults<CaseSearchRequestFilter>(null, presentation, parameters)
                       .Returns(searchResult);

                var r = await fixture.Subject.GetRecentCaseSearchResult(parameters);

                Assert.Equal(searchResult, r);
            }
        }

        public class GetDueDateOnlyCaseSearchResultMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnCaseSearchResultWithDueDateFilterApplied()
            {
                var queryKey = Fixture.Integer();
                var parameters = new CommonQueryParameters();
                var filter = new CaseSearchRequestFilter
                {
                    DueDateFilter = new DueDateFilter
                    {
                        DueDates = new DueDates
                        {
                            ImportanceLevel = new DueDateImportanceLevel
                            {
                                From = "5",
                                To = "9"
                            }
                        }
                    }
                };

                const string expected = "<filterCriteria><csw_ListCase><ColumnFilterCriteria><DueDates UseEventDates=\"0\" UseAdHocDates=\"0\"><ImportanceLevel Operator=\"0\"><From>5</From><To>9</To></ImportanceLevel></DueDates></ColumnFilterCriteria></csw_ListCase></filterCriteria>";

                var presentation = new SearchPresentation
                {
                    XmlCriteria = "<filterCriteria><csw_ListCase /></filterCriteria>"
                };
                var searchResult = new SearchResult();

                var fixture = new CaseSearchServiceFixture(Db);

                fixture.SearchPresentationService.GetSearchPresentation(QueryContext.CaseSearch, queryKey)
                       .Returns(presentation);

                fixture.Search.GetFormattedSearchResults<CaseSearchRequestFilter>(null, presentation, parameters)
                       .Returns(searchResult);

                var r = await fixture.Subject.GetDueDateOnlyCaseSearchResult(queryKey, filter, parameters);

                Assert.Equal(searchResult, r);
                Assert.Equal(expected, XElement.Parse(presentation.XmlCriteria).ToString(SaveOptions.DisableFormatting));
            }
        }

        public class DueDatePresentationMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldCorrectlySetHasDueDatePresentationColumn(bool isExternal)
            {
                var f = new CaseSearchServiceFixture(Db, isExternal);
                var pc = new List<PresentationColumn> { new PresentationColumn { ColumnKey = 1, ProcedureItemId = "DueDate" } };

                new QueryContextColumn { GroupId = isExternal ? -45 : -44, ColumnId = 1 }.In(Db);

                f.PresentationColumnResolver.Resolve(Arg.Any<int?>(), Arg.Any<QueryContext?>()).Returns(pc);

                var result = f.Subject.DueDatePresentationColumn(null);
                Assert.Equal(result.HasDueDatePresentationColumn, true);
                Assert.Equal(result.HasAllDatePresentationColumn, false);
            }

            [Fact]
            public void ShouldCorrectlySetHasAllDatePresentationColumn()
            {
                var f = new CaseSearchServiceFixture(Db);
                var pc = new List<PresentationColumn> { new PresentationColumn { ColumnKey = 1, ProcedureItemId = "DatesCycleAny" } };

                f.PresentationColumnResolver.Resolve(Arg.Any<int?>(), Arg.Any<QueryContext?>()).Returns(pc);

                var result = f.Subject.DueDatePresentationColumn(2);
                Assert.Equal(result.HasDueDatePresentationColumn, false);
                Assert.Equal(result.HasAllDatePresentationColumn, true);
            }

            [Fact]
            public void ShouldSetHasDueDatePresentationToFalseIfNoDueDateColumnExists()
            {
                var f = new CaseSearchServiceFixture(Db);
                f.PresentationColumnResolver.Resolve(Arg.Any<int?>(), Arg.Any<QueryContext?>()).Returns(new List<PresentationColumn>());

                var result = f.Subject.DueDatePresentationColumn(null);

                Assert.Equal(result.HasDueDatePresentationColumn, false);
            }
        }

        public class DistinctCaseIdsForBulkOperationsMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnDistinctIds()
            {
                var f = new CaseSearchServiceFixture(Db);
                var pc = new List<PresentationColumn> { new PresentationColumn { ColumnKey = 1, ProcedureItemId = "CaseReference" } };
                var rows = new List<Dictionary<string, object>>
                {
                    new Dictionary<string, object>
                    {
                        {"CaseKey", 1}
                    },
                    new Dictionary<string, object>
                    {
                        {"CaseKey", 2}
                    },
                    new Dictionary<string, object>
                    {
                        {"CaseKey", 2}
                    }
                };

                f.PresentationColumnResolver.AvailableColumns(Arg.Any<QueryContext>()).Returns(pc);
                f.SearchService.RunSearch(Arg.Any<SearchExportParams<CaseSearchRequestFilter>>()).Returns(new SearchResult { Rows = rows });

                var result = await f.Subject.DistinctCaseIdsForBulkOperations(new SearchExportParams<CaseSearchRequestFilter>());

                Assert.NotNull(result);
                var caseIds = result.ToArray();
                Assert.Equal(caseIds.Count(), 2);
                Assert.Equal(caseIds[0], 1);
                Assert.Equal(caseIds[1], 2);
            }

            [Fact]
            public async Task ShouldThrowExceptionIfNoRowsReturned()
            {
                var f = new CaseSearchServiceFixture(Db);
                var pc = new List<PresentationColumn> { new PresentationColumn { ColumnKey = 1, ProcedureItemId = "CaseReference" } };
                var rows = new List<Dictionary<string, object>>();

                f.PresentationColumnResolver.AvailableColumns(Arg.Any<QueryContext>()).Returns(pc);
                f.SearchService.RunSearch(Arg.Any<SearchExportParams<CaseSearchRequestFilter>>()).Returns(new SearchResult { Rows = rows });

                var e = await Record.ExceptionAsync(() => f.Subject.DistinctCaseIdsForBulkOperations(new SearchExportParams<CaseSearchRequestFilter>()));

                Assert.IsType<ArgumentException>(e);
            }
        }

        public class UpdateFilterForBulkOperationMethod : FactBase
        {
            [Fact]
            public void ShouldUpdateXmlCriteriaForSavedSearch()
            {
                var f = new CaseSearchServiceFixture(Db);

                var queryFiler = Db.Set<QueryFilter>().Add(new QueryFilter { ProcedureName = "csw_ListCase", XmlFilterCriteria = PrepareFilterCriteria() }).In(Db);
                var query = Db.Set<Query>().Add(new Query { Name = "Search 1", ContextId = 2, IdentityId = null, FilterId = queryFiler.Id }).In(Db);

                var searchParams = new SearchExportParams<CaseSearchRequestFilter>
                {
                    QueryKey = query.Id,
                    DeselectedIds = new[] { 1, 2, 3 },
                    Criteria = new CaseSearchRequestFilter
                    {
                        DueDateFilter = new DueDateFilter
                        {
                            DueDates = new DueDates
                            {
                                ImportanceLevel = new DueDateImportanceLevel
                                {
                                    From = "5",
                                    To = "9"
                                }
                            }
                        }
                    }
                };

                f.Subject.UpdateFilterForBulkOperation(searchParams);
                var xmlCriteria = XElement.Parse(searchParams.Criteria.XmlSearchRequest);
                Assert.NotNull(xmlCriteria);

                Assert.Equal(3, xmlCriteria.DescendantsAndSelf("FilterCriteria").Count());

                var addedStep = xmlCriteria.DescendantsAndSelf("FilterCriteria").Last().ToString();
                Assert.Equal(addedStep, "<FilterCriteria ID=\"3\" BooleanOperator=\"AND\">\r\n  <CaseKeys Operator=\"1\">1,2,3</CaseKeys>\r\n</FilterCriteria>");

                var dueDateFilter = xmlCriteria.DescendantsAndSelf("DueDates").First().ToString();

                Assert.Equal(dueDateFilter, "<DueDates UseEventDates=\"0\" UseAdHocDates=\"0\">\r\n  <ImportanceLevel Operator=\"0\">\r\n    <From>5</From>\r\n    <To>9</To>\r\n  </ImportanceLevel>\r\n</DueDates>");

            }

            [Fact]
            public void ShouldUpdateXmlCriteriaForRequestWithXmlCriteria()
            {
                var f = new CaseSearchServiceFixture(Db);
                var searchParams = new SearchExportParams<CaseSearchRequestFilter>
                {
                    DeselectedIds = new[] { 1, 2, 3 },
                    Criteria = new CaseSearchRequestFilter
                    {
                        XmlSearchRequest = PrepareFilterCriteria(),
                    }
                };

                f.Subject.UpdateFilterForBulkOperation(searchParams);
                var xmlCriteria = XElement.Parse(searchParams.Criteria.XmlSearchRequest);
                Assert.NotNull(xmlCriteria);

                Assert.Equal(3, xmlCriteria.DescendantsAndSelf("FilterCriteria").Count());
                var addedStep = xmlCriteria.DescendantsAndSelf("FilterCriteria").Last().ToString();
                Assert.Equal(addedStep, "<FilterCriteria ID=\"3\" BooleanOperator=\"AND\">\r\n  <CaseKeys Operator=\"1\">1,2,3</CaseKeys>\r\n</FilterCriteria>");
            }

            static string PrepareFilterCriteria()
            {
                const string filterCriteria = @"<Search><Report><ReportTitle>AU</ReportTitle></Report><Filtering><csw_ListCase>
                                <FilterCriteriaGroup>
                                    <FilterCriteria ID='1'>
                                        <AccessMode>1</AccessMode>
                                        <IsAdvancedFilter>false</IsAdvancedFilter>
                                        <CountryCodes Operator='0'>AU</CountryCodes><InheritedName /><CaseNameGroup />
                                    </FilterCriteria>
                                    <FilterCriteria BooleanOperator='OR' ID='2'>
                                        <AccessMode>1</AccessMode>
                                        <IsAdvancedFilter>false</IsAdvancedFilter>
                                        <CaseReference Operator='2'>1234</CaseReference><InheritedName /><CaseNameGroup />
                                    </FilterCriteria>                                    
                                </FilterCriteriaGroup></csw_ListCase></Filtering></Search>";
                return filterCriteria;
            }

            [Fact]
            public void ShouldAddStepForRemovingCasesIfRequestHasDeselectedCases()
            {
                var f = new CaseSearchServiceFixture(Db);
                var searchParams = new SearchExportParams<CaseSearchRequestFilter>
                {
                    DeselectedIds = new[] { 1, 2 },
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new[]
                        {
                            new CaseSearchRequest
                            {
                                CaseKeys = new SearchElement {Value = "1,2"}
                            }
                        }
                    },
                };

                f.Subject.UpdateFilterForBulkOperation(searchParams);

                Assert.Equal(searchParams.Criteria.SearchRequest.ToList().Count, 2);

                var addedStep = searchParams.Criteria.SearchRequest.ToList().Last();

                Assert.Equal(addedStep.Operator, "AND");
                Assert.Equal(addedStep.CaseKeys.Operator, (short)CollectionExtensions.FilterOperator.NotIn);
                Assert.Equal(addedStep.CaseKeys.Value, "1,2");
            }

            [Fact]
            public void ShouldNotAddAnyStepIfRequestDoesNotHaveDeselectedCases()
            {
                var f = new CaseSearchServiceFixture(Db);
                var searchParams = new SearchExportParams<CaseSearchRequestFilter>
                {
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new[]
                        {
                            new CaseSearchRequest
                            {
                                CaseKeys = new SearchElement {Value = "1,2"}
                            }
                        }
                    }
                };

                f.Subject.UpdateFilterForBulkOperation(searchParams);

                Assert.Equal(searchParams.Criteria.SearchRequest.ToList().Count, 1);
            }

            [Fact]
            public void ShouldReturnXmlFilterCriteriaAsItIs()
            {
                var f = new CaseSearchServiceFixture(Db);

                const string filterCriteria = @"<Search><Report><ReportTitle>AU</ReportTitle></Report><Filtering><csw_ListCase>
                                <FilterCriteriaGroup>
                                    <FilterCriteria ID='1'>
                                        <AccessMode>1</AccessMode>
                                        <IsAdvancedFilter>false</IsAdvancedFilter>
                                        <CountryCodes Operator='0'>AU</CountryCodes><InheritedName /><CaseNameGroup />
                                    </FilterCriteria>
                                    <FilterCriteria BooleanOperator='OR' ID='2'>
                                        <AccessMode>1</AccessMode>
                                        <IsAdvancedFilter>false</IsAdvancedFilter>
                                        <CaseReference Operator='2'>1234</CaseReference><InheritedName /><CaseNameGroup />
                                    </FilterCriteria>                                    
                                </FilterCriteriaGroup></csw_ListCase></Filtering></Search>";

                var searchParams = new SearchExportParams<CaseSearchRequestFilter>
                {
                    QueryKey = 1,
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new[]
                        {
                            new CaseSearchRequest( )
                        },
                        XmlSearchRequest = filterCriteria
                    }
                };

                f.Subject.UpdateFilterForBulkOperation(searchParams);

                Assert.Equal(filterCriteria, searchParams.Criteria.XmlSearchRequest);
            }

            [Fact]
            public void XmlFilterCriteriaShouldNotBeNull()
            {
                var f = new CaseSearchServiceFixture(Db);
                var searchParams = new SearchExportParams<CaseSearchRequestFilter>
                {
                    QueryContext = QueryContext.CaseSearch,
                    QueryKey = 1,
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new[]
                        {
                            new CaseSearchRequest( )
                        }
                    }
                };
                var sf = new SearchFacts.SearchFixture();
                f.FilterableColumnsMapResolver.Resolve(QueryContext.CaseSearch).Returns(sf.FilterableColumnsMap);
                f.XmlFilterCriteriaBuilderResolver.Resolve(QueryContext.CaseSearch).Returns(new CaseXmlFilterCriteriaBuilder());

                Assert.Null(searchParams.Criteria.XmlSearchRequest);
                f.Subject.UpdateFilterForBulkOperation(searchParams);
                Assert.NotNull(searchParams.Criteria.XmlSearchRequest);
            }
        }

        public class CaseSearchServiceFixture : IFixture<ICaseSearchService>
        {
            public CaseSearchServiceFixture(InMemoryDbContext db, bool withExternalUser = false)
            {
                SearchService = Substitute.For<ISearchService>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Search = Substitute.For<ISearch>();
                SearchPresentationService = Substitute.For<ISearchPresentationService>();
                DbContext = db ?? Substitute.For<InMemoryDbContext>();
                PresentationColumnResolver = Substitute.For<IPresentationColumnsResolver>();
                ImportanceLevelResolver = Substitute.For<IImportanceLevelResolver>();
                ImportanceLevelResolver.Resolve().Returns(2);
                SecurityContext = Substitute.For<ISecurityContext>();

                XmlFilterCriteriaBuilderResolver = Substitute.For<IXmlFilterCriteriaBuilderResolver>();
                FilterableColumnsMapResolver = Substitute.For<IFilterableColumnsMapResolver>();

                var user = new User("user", withExternalUser).In(DbContext);
                SecurityContext.User.Returns(user);
                Subject = new CaseSearchService(DbContext,
                                                SecurityContext,
                                                PreferredCultureResolver,
                                                Search,
                                                SearchPresentationService, 
                                                PresentationColumnResolver, 
                                                ImportanceLevelResolver, 
                                                SearchService,
                                                XmlFilterCriteriaBuilderResolver,
                                                FilterableColumnsMapResolver
                                                );
            }

            public ISearch Search { get; }
            public ISearchPresentationService SearchPresentationService { get; set; }
            public InMemoryDbContext DbContext { get; set; }
            public IPresentationColumnsResolver PresentationColumnResolver { get; set; }
            public IImportanceLevelResolver ImportanceLevelResolver { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ISearchService SearchService { get; set; }
            public ICaseSearchService Subject { get; set; }

            public ISecurityContext SecurityContext { get; set; }

            public IXmlFilterCriteriaBuilderResolver XmlFilterCriteriaBuilderResolver { get; set; }
            public IFilterableColumnsMapResolver FilterableColumnsMapResolver { get; set; }
        }
    }
}