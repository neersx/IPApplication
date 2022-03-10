using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Queries;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search
{
    public class SearchServiceFacts
    {
        public class AnySuperfluousFilter : SearchRequestFilter
        {
        }

        public class RunSearchMethod
        {
            [Theory]
            [InlineData("country_7", "country", "mappedCountryField")]
            [InlineData("caseRef", "caseRef", "mappedCaseRefField")]
            public async Task ShouldApplyCommonQueryParameters(string filterName, string extractedColumnName, string mappedField)
            {
                var filter = new SavedSearchRequestParams<AnySuperfluousFilter>
                {
                    Params = new CommonQueryParameters
                    {
                        Filters = new[]
                        {
                            new CommonQueryParameters.FilterValue
                            {
                                Field = filterName
                            }
                        }
                    },
                    Criteria = new AnySuperfluousFilter()
                };
                var presentation = new SearchPresentation();
                var results = new SearchResult();

                var f = new SearchServiceFixture();

                f.SearchPresentationService
                 .GetSearchPresentation(Arg.Any<QueryContext>())
                 .ReturnsForAnyArgs(presentation);

                f.SearchPresentationService.GetMatchingColumnCode(Arg.Any<QueryContext>(), extractedColumnName).Returns(mappedField);

                f.Search
                 .GetFormattedSearchResults(filter.Criteria, presentation, Arg.Any<CommonQueryParameters>())
                 .Returns(results);

                var r = await f.Subject.RunSearch(filter);

                Assert.Equal(results, r);
                Assert.Equal(filter.Params.Filters.Single().Field, mappedField);
            }

            [Fact]
            public async Task ShouldGetSearchResult()
            {
                var filter = new SavedSearchRequestParams<AnySuperfluousFilter>
                {
                    QueryContext = QueryContext.ActivityAttachmentList,
                    SelectedColumns = new List<SelectedColumn>
                    {
                        new SelectedColumn {ColumnKey = 1, DisplaySequence = 1}
                    },
                    Criteria = new AnySuperfluousFilter
                    {
                        XmlSearchRequest = Fixture.String(),
                        PresentationType = Fixture.String()
                    }
                };

                var presentation = new SearchPresentation();
                var results = new SearchResult();

                var f = new SearchServiceFixture();

                f.SearchPresentationService
                 .GetSearchPresentation(filter.QueryContext, null, filter.SelectedColumns, filter.Criteria.PresentationType)
                 .Returns(presentation);

                f.Search
                 .GetFormattedSearchResults(filter.Criteria, presentation, Arg.Any<CommonQueryParameters>())
                 .Returns(results);

                var r = await f.Subject.RunSearch(filter);

                Assert.Equal(results, r);
                Assert.Equal(filter.Criteria.XmlSearchRequest, presentation.XmlCriteria);

                f.Search.Received(1)
                 .GetFormattedSearchResults(filter.Criteria,
                                            Arg.Is<SearchPresentation>(_ => _.XmlCriteria == filter.Criteria.XmlSearchRequest),
                                            Arg.Any<CommonQueryParameters>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.SearchPresentationService.Received(1)
                 .UpdatePresentationForColumnSort(presentation, Arg.Any<string>(), Arg.Any<string>());
            }
        }

        public class RunSavedSearchMethod
        {
            [Theory]
            [InlineData("country_7", "country", "mappedCountryField")]
            [InlineData("caseRef", "caseRef", "mappedCaseRefField")]
            public async Task ShouldApplyCommonQueryParameters(string filterName, string extractedColumnName, string mappedField)
            {
                var filter = new SavedSearchRequestParams<AnySuperfluousFilter>
                {
                    Params = new CommonQueryParameters
                    {
                        Filters = new[]
                        {
                            new CommonQueryParameters.FilterValue
                            {
                                Field = filterName
                            }
                        }
                    }
                };
                var presentation = new SearchPresentation();
                var results = new SearchResult();

                var f = new SearchServiceFixture();

                f.SearchPresentationService
                 .GetSearchPresentation(Arg.Any<QueryContext>())
                 .ReturnsForAnyArgs(presentation);

                f.SearchPresentationService.GetMatchingColumnCode(Arg.Any<QueryContext>(), extractedColumnName).Returns(mappedField);

                f.Search
                 .GetFormattedSearchResults(filter.Criteria, presentation, Arg.Any<CommonQueryParameters>())
                 .Returns(results);

                var r = await f.Subject.RunSavedSearch(filter);

                Assert.Equal(results, r);
                Assert.Equal(filter.Params.Filters.Single().Field, mappedField);
                await f.SavedSearchValidator.Received(1).ValidateQueryExists(Arg.Any<QueryContext>(), Arg.Any<int>(), true);
            }

            [Fact]
            public async Task ShouldGetSavedSearchResult()
            {
                var filter = new SavedSearchRequestParams<AnySuperfluousFilter>
                {
                    QueryContext = QueryContext.ActivityAttachmentList,
                    QueryKey = Fixture.Integer(),
                    SelectedColumns = new List<SelectedColumn>
                    {
                        new SelectedColumn {ColumnKey = 1, DisplaySequence = 1}
                    },
                    Criteria = new AnySuperfluousFilter
                    {
                        XmlSearchRequest = "This should not flow into presentation.XmlFilterCriteria due to this running a Saved Search"
                    }
                };

                var presentation = new SearchPresentation();
                var results = new SearchResult();

                var f = new SearchServiceFixture();

                f.SearchPresentationService
                 .GetSearchPresentation(filter.QueryContext, filter.QueryKey, filter.SelectedColumns)
                 .Returns(presentation);

                f.Search
                 .GetFormattedSearchResults(Arg.Any<AnySuperfluousFilter>(), presentation, Arg.Any<CommonQueryParameters>())
                 .Returns(results);

                var r = await f.Subject.RunSavedSearch(filter);

                Assert.Equal(results, r);
                Assert.Null(presentation.XmlFilterCriteria);

                f.SearchPresentationService.Received(1)
                 .UpdatePresentationForColumnSort(presentation, Arg.Any<string>(), Arg.Any<string>());

                await f.SavedSearchValidator.Received(1).ValidateQueryExists(filter.QueryContext, filter.QueryKey.GetValueOrDefault(), true);
            }
        }

        public class RunEditedSavedSearchMethod
        {
            [Theory]
            [InlineData("country_7", "country", "mappedCountryField")]
            [InlineData("caseRef", "caseRef", "mappedCaseRefField")]
            public async Task ShouldApplyCommonQueryParameters(string filterName, string extractedColumnName, string mappedField)
            {
                var filter = new SavedSearchRequestParams<AnySuperfluousFilter>
                {
                    Params = new CommonQueryParameters
                    {
                        Filters = new[]
                        {
                            new CommonQueryParameters.FilterValue
                            {
                                Field = filterName
                            }
                        }
                    },
                    Criteria = new AnySuperfluousFilter()
                };
                var presentation = new SearchPresentation();
                var results = new SearchResult();

                var f = new SearchServiceFixture();

                f.SearchPresentationService
                 .GetSearchPresentation(Arg.Any<QueryContext>())
                 .ReturnsForAnyArgs(presentation);

                f.SearchPresentationService.GetMatchingColumnCode(Arg.Any<QueryContext>(), extractedColumnName).Returns(mappedField);

                f.Search
                 .GetFormattedSearchResults(filter.Criteria, presentation, Arg.Any<CommonQueryParameters>())
                 .Returns(results);

                var r = await f.Subject.RunEditedSavedSearch(filter);

                Assert.Equal(results, r);
                Assert.Equal(filter.Params.Filters.Single().Field, mappedField);

                await f.SavedSearchValidator.Received(1).ValidateQueryExists(Arg.Any<QueryContext>(), Arg.Any<int>(), true);
            }

            [Fact]
            public async Task ShouldGetEditedSavedSearchResult()
            {
                var filter = new SavedSearchRequestParams<AnySuperfluousFilter>
                {
                    QueryContext = QueryContext.ActivityAttachmentList,
                    QueryKey = Fixture.Integer(),
                    SelectedColumns = new List<SelectedColumn>
                    {
                        new SelectedColumn {ColumnKey = 1, DisplaySequence = 1}
                    },
                    Criteria = new AnySuperfluousFilter
                    {
                        XmlSearchRequest = Fixture.String()
                    }
                };

                var presentation = new SearchPresentation();
                var results = new SearchResult();

                var f = new SearchServiceFixture();

                f.SearchPresentationService
                 .GetSearchPresentation(filter.QueryContext, filter.QueryKey, filter.SelectedColumns)
                 .Returns(presentation);

                f.Search
                 .GetFormattedSearchResults(filter.Criteria, presentation, Arg.Any<CommonQueryParameters>())
                 .Returns(results);

                var r = await f.Subject.RunEditedSavedSearch(filter);

                Assert.Equal(results, r);
                Assert.Equal(filter.Criteria.XmlSearchRequest, presentation.XmlCriteria);

                f.Search.Received(1)
                 .GetFormattedSearchResults(filter.Criteria,
                                            Arg.Is<SearchPresentation>(_ => _.XmlCriteria == filter.Criteria.XmlSearchRequest),
                                            Arg.Any<CommonQueryParameters>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.SearchPresentationService.Received(1)
                 .UpdatePresentationForColumnSort(presentation, Arg.Any<string>(), Arg.Any<string>());

                await f.SavedSearchValidator.Received(1).ValidateQueryExists(filter.QueryContext, filter.QueryKey.GetValueOrDefault(), true);
            }
        }

        public class GetSearchExportDataMethod
        {
            [Fact]
            public async Task ShouldGetExportDataForDynamicSearchResult()
            {
                var filter = new AnySuperfluousFilter();
                var queryContext = QueryContext.ActivityAttachmentList;
                var forceBuildCriteria = Fixture.Boolean();
                var selectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1}
                };

                var presentation = new SearchPresentation();
                var results = new InprotechKaizen.Model.Components.Queries.SearchResults();

                var f = new SearchServiceFixture();

                f.SearchPresentationService
                 .GetSearchPresentation(queryContext, selectedColumns: selectedColumns)
                 .Returns(presentation);

                f.Search
                 .GetSearchResults(filter, presentation, Arg.Any<CommonQueryParameters>(), forceBuildCriteria)
                 .Returns(results);

                var r = await f.Subject.GetSearchExportData(filter, new CommonQueryParameters(), null, queryContext, selectedColumns, forceBuildCriteria);

                Assert.Equal(results, r.SearchResults);
                Assert.Equal(presentation, r.Presentation);

                f.SearchPresentationService.Received(1)
                 .UpdatePresentationForColumnSort(presentation, Arg.Any<string>(), Arg.Any<string>());
            }

            [Fact]
            public async Task ShouldGetExportDataForSavedSearchResult()
            {
                var filter = new AnySuperfluousFilter();
                var queryKey = Fixture.Integer();
                var queryContext = QueryContext.ActivityAttachmentList;
                var forceBuildCriteria = Fixture.Boolean();
                var selectedColumns = new List<SelectedColumn>
                {
                    new SelectedColumn {ColumnKey = 1, DisplaySequence = 1}
                };

                var presentation = new SearchPresentation();
                var results = new InprotechKaizen.Model.Components.Queries.SearchResults();

                var f = new SearchServiceFixture();

                f.SearchPresentationService
                 .GetSearchPresentation(queryContext, queryKey, selectedColumns)
                 .Returns(presentation);

                f.Search
                 .GetSearchResults(filter, presentation, Arg.Any<CommonQueryParameters>(), forceBuildCriteria)
                 .Returns(results);

                var r = await f.Subject.GetSearchExportData(filter, new CommonQueryParameters(), queryKey, queryContext, selectedColumns, forceBuildCriteria);

                Assert.Equal(results, r.SearchResults);
                Assert.Equal(presentation, r.Presentation);

                f.SearchPresentationService.Received(1)
                 .UpdatePresentationForColumnSort(presentation, Arg.Any<string>(), Arg.Any<string>());
            }
        }

        public class GetSearchColumnsMethod
        {
            [Fact]
            public async Task ShouldReturnSearchColumns()
            {
                var queryContext = QueryContext.AccessAccountPickList;
                var queryKey = Fixture.Integer();
                var presentationType = Fixture.String();
                var selectedColumns = new SelectedColumn[0];

                var f = new SearchServiceFixture();
                f.SearchPresentationService.GetSearchPresentation(queryContext, queryKey, selectedColumns, presentationType)
                 .Returns(new SearchPresentation
                 {
                     ColumnFormats = new List<ColumnFormat>
                     {
                         new ColumnFormat
                         {
                             CurrencyCodeColumnName = "BillingFeeCurrency_1996_",
                             DecimalPlaces = 2,
                             Filterable = true,
                             Id = "Amount",
                             IsColumnFreezed = true,
                             Links = new List<Link>
                             {
                                 new Link
                                 {
                                     Id = "CaseId",
                                     Type = "CaseDetails",
                                     LinkArguments =
                                     {
                                         new LinkArgument
                                         {
                                             Id = "CaseId",
                                             Source = "CaseKey"
                                         },
                                         new LinkArgument
                                         {
                                             Id = "CaseRef",
                                             Source = "CaseRef_1"
                                         }
                                     }
                                 }
                             }
                         }
                     }
                 });

                var r = (await f.Subject.GetSearchColumns(queryContext, queryKey, selectedColumns, presentationType)).ToArray().Single();

                Assert.Equal("billingFeeCurrency_1996_", r.CurrencyCodeColumnName);
                Assert.Equal(2, r.DecimalPlaces);
                Assert.Equal("amount", r.Id);
                Assert.True(r.Filterable);
                Assert.True(r.IsColumnFreezed);
                Assert.Equal("CaseDetails", r.LinkType);
                Assert.Equal(new[] { "caseKey", "caseRef_1" }, r.LinkArgs.ToArray());
            }
        }

        public class GetFilterDataForColumnMethod
        {
            [Fact]
            public async Task ShouldGetFilterDataForColumnResult()
            {
                var sr =
                    new InprotechKaizen.Model.Components.Queries.SearchResults
                    {
                        RowCount = 3,
                        TotalRows = 3,
                        Rows = new List<Dictionary<string, object>>
                        {
                            new Dictionary<string, object>
                            {
                                {"CountryName", "cell 1-1"},
                                {"CountryCode", "c1-1"},
                                {"CaseTypeDescription", "cell 2-1"},
                                {"PropertyTypeDescription", "cell 3-1"}
                            },

                            new Dictionary<string, object>
                            {
                                {"CountryName", "cell 1-2"},
                                {"CountryCode", "c1-2"},
                                {"CaseTypeDescription", "cell 2-2"},
                                {"PropertyTypeDescription", "cell 3-2"}
                            },

                            new Dictionary<string, object>
                            {
                                {"CountryName", "cell 1-3"},
                                {"CountryCode", "c1-3"},
                                {"CaseTypeDescription", "cell 2-3"},
                                {"PropertyTypeDescription", "cell 3-3"}
                            }
                        }
                    };

                var presentation = new SearchPresentation();
                var fixture = new SearchServiceFixture();

                fixture.SearchPresentationService.GetMatchingColumnCode(Arg.Any<QueryContext>(), "CountryName")
                       .Returns("CountryCode");

                fixture.SearchPresentationService.GetSearchPresentation(QueryContext.CaseSearch, 1)
                       .Returns(presentation);

                fixture.Search
                       .GetSearchResults(Arg.Any<AnySuperfluousFilter>(), presentation, Arg.Any<CommonQueryParameters>())
                       .ReturnsForAnyArgs(sr);

                var result = (await fixture.Subject
                                           .GetFilterDataForColumn(
                                                                   new ColumnFilterParams<AnySuperfluousFilter>
                                                                   {
                                                                       QueryContext = QueryContext.CaseSearch,
                                                                       QueryKey = 1,
                                                                       Criteria = new AnySuperfluousFilter(),
                                                                       Column = "CountryName",
                                                                       Params = new CommonQueryParameters()
                                                                   })).ToArray();

                Assert.Equal(3, result.Length);
                Assert.True(result.Any(r => r.Code.Equals("c1-2") && r.Description.Equals("cell 1-2")));
            }
        }

        public class SearchServiceFixture : IFixture<SearchService>
        {
            public SearchServiceFixture()
            {
                Search = Substitute.For<ISearch>();
                SearchPresentationService = Substitute.For<ISearchPresentationService>();
                SavedSearchValidator = Substitute.For<ISavedSearchValidator>();

                Subject = new SearchService(Search, SearchPresentationService, SavedSearchValidator);
            }

            public ISearchPresentationService SearchPresentationService { get; set; }

            public ISavedSearchValidator SavedSearchValidator { get; set; }

            public ISearch Search { get; set; }

            public SearchService Subject { get; }
        }
    }
}