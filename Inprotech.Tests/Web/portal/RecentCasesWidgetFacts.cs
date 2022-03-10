using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Portal;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Portal
{
    public class RecentCasesWidgetFacts
    {
        [Fact]
        public async Task ColumnsAndRowsReturned()
        {
            // setup fake data from stored procs and make sure it makes its way to the client

            var fixture = new RecentCasesWidgetFixture();

            fixture.SearchService.GetRecentCaseSearchResult(null)
                   .ReturnsForAnyArgs(new SearchResult
                   {
                       TotalRows = 3,
                       Rows = new List<Dictionary<string, object>>
                       {
                           new Dictionary<string, object>
                           {
                               {"col1", "cell 1-1"},
                               {"col2", "cell 2-1"},
                               {"col3", "cell 3-1"}
                           },

                           new Dictionary<string, object>
                           {
                               {"col1", "cell 1-2"},
                               {"col2", "cell 2-2"},
                               {"col3", "cell 3-2"}
                           },
                           new Dictionary<string, object>
                           {
                               {"col1", "cell 1-3"},
                               {"col2", "cell 2-3"},
                               {"col3", "cell 3-3"}
                           }
                       },
                       Columns = new List<SearchResult.Column>
                       {
                           new SearchResult.Column
                           {
                               Id = "col1"
                           },
                           new SearchResult.Column
                           {
                               Id = "col2"
                           },
                           new SearchResult.Column
                           {
                               Id = "col3"
                           }
                       }
                   });

            var qp = CommonQueryParameters.Default;

            var result = await fixture.Subject.Get(qp);

            Assert.Equal(3, result.TotalRows);
            Assert.Equal(3, result.Rows.Count());
            Assert.Equal(3, result.Columns.Count());

            Assert.Equal("col1", result.Columns.ElementAt(0).Id);
            Assert.Equal("col2", result.Columns.ElementAt(1).Id);
            Assert.Equal("col3", result.Columns.ElementAt(2).Id);

            Assert.Equal("cell 1-1", result.Rows.ElementAt(0).First().Value);
            Assert.Equal("cell 1-2", result.Rows.ElementAt(1).First().Value);
            Assert.Equal("cell 1-3", result.Rows.ElementAt(2).First().Value);
        }
    }

    internal class RecentCasesWidgetFixture : IFixture<RecentCasesController>
    {
        public RecentCasesWidgetFixture()
        {
            SearchService = Substitute.For<ICaseSearchService>();
            ListCasePrograms = Substitute.For<IListPrograms>();
            Subject = new RecentCasesController(SearchService, ListCasePrograms);
        }

        public ICaseSearchService SearchService { get; }

        public IListPrograms ListCasePrograms { get; set; }

        public RecentCasesController Subject { get; }
    }
}