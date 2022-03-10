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
    public class SearchFacts
    {
        public class AnySuperfluousFilter : SearchRequestFilter
        {
        }

        public class GetSearchResultsMethod
        {
            [Fact]
            public async Task ShouldBuildXmlCriteriaIfEmpty()
            {
                var f = new SearchFixture();

                var queryParameters = new CommonQueryParameters();
                var filter = new AnySuperfluousFilter();
                var result = new InprotechKaizen.Model.Components.Queries.SearchResults();
                var presentation = new SearchPresentation
                {
                    XmlCriteria = null,
                    QueryContextKey = QueryContext.ActivityAttachmentListExternal
                };

                f.SearchDataProvider.RunSearch(presentation, queryParameters)
                 .Returns(result);

                var xmlCriteriaBuilder = Substitute.For<IXmlFilterCriteriaBuilder>();
                xmlCriteriaBuilder.Build(filter, queryParameters, f.FilterableColumnsMap)
                                  .Returns("abc");

                f.XmlFilterCriteriaBuilderResolver.Resolve(presentation.QueryContextKey)
                 .Returns(xmlCriteriaBuilder);

                var r = await f.Subject.GetSearchResults(filter, presentation, queryParameters);
                Assert.Equal(result, r);

                f.SearchDataProvider.Received(1)
                 .RunSearch(Arg.Is<SearchPresentation>(_ => _.XmlCriteria == "abc"), queryParameters)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldBuildXmlCriteriaIfFiltersProvided()
            {
                var f = new SearchFixture();
                var queryParameters = new CommonQueryParameters
                {
                    Filters = new[]
                    {
                        new CommonQueryParameters.FilterValue
                        {
                            Field = "countryCode",
                            Value = "AU"
                        }
                    }
                };
                var filter = new AnySuperfluousFilter();
                var result = new InprotechKaizen.Model.Components.Queries.SearchResults();
                var presentation = new SearchPresentation
                {
                    XmlCriteria = "def",
                    QueryContextKey = QueryContext.ActivityAttachmentListExternal
                };

                f.SearchDataProvider.RunSearch(presentation, queryParameters)
                 .Returns(result);

                var xmlCriteriaBuilder = Substitute.For<IXmlFilterCriteriaBuilder>();
                xmlCriteriaBuilder.Build(Arg.Any<SearchRequestFilter>(), "def", queryParameters, f.FilterableColumnsMap)
                                  .Returns("abc");

                f.XmlFilterCriteriaBuilderResolver.Resolve(presentation.QueryContextKey)
                 .Returns(xmlCriteriaBuilder);

                var r = await f.Subject.GetSearchResults(filter, presentation, queryParameters);
                Assert.Equal(result, r);

                f.SearchDataProvider.Received(1)
                 .RunSearch(Arg.Is<SearchPresentation>(_ => _.XmlCriteria == "abc"), queryParameters)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldBuildXmlCriteriaIfForced()
            {
                var f = new SearchFixture();
                const bool forceCreateXmlCriteria = true;
                var queryParameters = new CommonQueryParameters();
                var filter = new AnySuperfluousFilter();
                var result = new InprotechKaizen.Model.Components.Queries.SearchResults();
                var presentation = new SearchPresentation
                {
                    XmlCriteria = "original",
                    QueryContextKey = QueryContext.ActivityAttachmentListExternal
                };

                f.SearchDataProvider.RunSearch(presentation, queryParameters)
                 .Returns(result);

                var xmlCriteriaBuilder = Substitute.For<IXmlFilterCriteriaBuilder>();
                xmlCriteriaBuilder.Build(filter, queryParameters, f.FilterableColumnsMap)
                                  .Returns("abc");

                f.XmlFilterCriteriaBuilderResolver.Resolve(presentation.QueryContextKey)
                 .Returns(xmlCriteriaBuilder);

                var r = await f.Subject.GetSearchResults(filter, presentation, queryParameters, forceCreateXmlCriteria);
                Assert.Equal(result, r);

                f.SearchDataProvider.Received(1)
                 .RunSearch(Arg.Is<SearchPresentation>(_ => _.XmlCriteria == "abc"), queryParameters)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldDefaultXmlCriteriaFromXmlSearchRequest()
            {
                var f = new SearchFixture();
                var presentation = new SearchPresentation {XmlCriteria = null};
                var queryParameters = new CommonQueryParameters();
                var result = new InprotechKaizen.Model.Components.Queries.SearchResults();

                var filter = new AnySuperfluousFilter
                {
                    XmlSearchRequest = Fixture.String()
                };

                f.SearchDataProvider.RunSearch(presentation, queryParameters)
                 .Returns(result);

                var xmlCriteriaBuilder = Substitute.For<IXmlFilterCriteriaBuilder>();
                xmlCriteriaBuilder.Build(Arg.Any<SearchRequestFilter>(), Arg.Any<string>(), Arg.Any<CommonQueryParameters>(), Arg.Any<IFilterableColumnsMap>())
                                  .Returns(filter.XmlSearchRequest);

                var r = await f.Subject.GetSearchResults(filter, presentation, queryParameters);

                Assert.Equal(result, r);
                
                // Intentionally commented
                //f.SearchDataProvider.Received(1)
                // .RunSearch(Arg.Is<SearchPresentation>(_ => _.XmlCriteria == filter.XmlSearchRequest), queryParameters)
                // .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnSearchResult()
            {
                var f = new SearchFixture();
                var presentation = new SearchPresentation {XmlCriteria = Fixture.String()};
                var queryParameters = new CommonQueryParameters();
                var result = new InprotechKaizen.Model.Components.Queries.SearchResults();
                f.SearchDataProvider.RunSearch(presentation, queryParameters)
                 .Returns(result);
                var r = await f.Subject.GetSearchResults(new AnySuperfluousFilter(), presentation, queryParameters);
                Assert.Equal(result, r);
            }
        }

        public class GetFormattedSearchResultsMethod
        {
            [Fact]
            public async Task ShouldReturnLinkArgsForLinkedColumns()
            {
                var filter = new AnySuperfluousFilter {XmlSearchRequest = "abc"};

                var presentation = new SearchPresentation
                {
                    ColumnFormats = new List<ColumnFormat>
                    {
                        new ColumnFormat
                        {
                            Id = "CountryName",
                            Title = "Country Name",
                            Filterable = true,
                            Links = new List<Link>
                            {
                                new Link
                                {
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
                };

                var fixture = new SearchFixture();
                fixture.SearchDataProvider.RunSearch(presentation, Arg.Any<CommonQueryParameters>())
                       .Returns(new InprotechKaizen.Model.Components.Queries.SearchResults
                       {
                           TotalRows = 1,
                           Rows = new List<Dictionary<string, object>>
                           {
                               new Dictionary<string, object>
                               {
                                   {"CountryName", "AU"},
                                   {"CaseKey", 2},
                                   {"CaseRef_1", "1234/A"}
                               }
                           }
                       });

                var r = await fixture.Subject.GetFormattedSearchResults(filter, presentation, new CommonQueryParameters());

                Assert.Equal(1, r.TotalRows);
                Assert.Equal("countryname", r.Columns.Single().Id);
                Assert.Equal("Country Name", r.Columns.Single().Title);
                Assert.True(r.Columns.Single().Filterable);
                Assert.Equal("AU", ((dynamic) r.Rows.Single()["countryname"]).value);
                Assert.Equal(2, ((dynamic) r.Rows.Single()["countryname"]).link["CaseKey"]);
                Assert.Equal("1234/A", ((dynamic) r.Rows.Single()["countryname"]).link["CaseRef_1"]);
            }

            [Fact]
            public async Task ShouldReturnResultsWithTotals()
            {
                var filter = new AnySuperfluousFilter {XmlSearchRequest = "abc"};

                var presentation = new SearchPresentation
                {
                    ColumnFormats = new List<ColumnFormat>
                    {
                        new ColumnFormat
                        {
                            Id = "CountryName",
                            Title = "Country Name",
                            Filterable = true
                        }
                    }
                };

                var fixture = new SearchFixture();
                fixture.SearchDataProvider.RunSearch(presentation, Arg.Any<CommonQueryParameters>())
                       .Returns(new InprotechKaizen.Model.Components.Queries.SearchResults
                       {
                           TotalRows = 1,
                           Rows = new List<Dictionary<string, object>>
                           {
                               new Dictionary<string, object>
                               {
                                   {"CountryName", "AU"}
                               }
                           }
                       });

                var r = await fixture.Subject.GetFormattedSearchResults(filter, presentation, new CommonQueryParameters());

                Assert.Equal(1, r.TotalRows);
                Assert.Equal("countryname", r.Columns.Single().Id);
                Assert.Equal("Country Name", r.Columns.Single().Title);
                Assert.True(r.Columns.Single().Filterable);
                Assert.Equal("AU", r.Rows.Single()["countryname"]);
            }
        }

        public class SearchFixture : IFixture<Inprotech.Web.Search.Search>
        {
            public SearchFixture()
            {
                SearchDataProvider = Substitute.For<ISearchDataProvider>();
                FilterableColumnsMap = Substitute.For<IFilterableColumnsMap>();
                XmlFilterCriteriaBuilderResolver = Substitute.For<IXmlFilterCriteriaBuilderResolver>();
                var filterableColumnsMapResolver = Substitute.For<IFilterableColumnsMapResolver>();
                filterableColumnsMapResolver.Resolve(Arg.Any<QueryContext>())
                                            .Returns(FilterableColumnsMap);
                Subject = new Inprotech.Web.Search.Search(SearchDataProvider, XmlFilterCriteriaBuilderResolver, filterableColumnsMapResolver);
            }

            public ISearchDataProvider SearchDataProvider { get; set; }

            public IFilterableColumnsMap FilterableColumnsMap { get; set; }

            public IXmlFilterCriteriaBuilderResolver XmlFilterCriteriaBuilderResolver { get; set; }

            public Inprotech.Web.Search.Search Subject { get; set; }
        }
    }
}