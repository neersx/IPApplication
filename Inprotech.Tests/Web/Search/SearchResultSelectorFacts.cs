using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using Xunit;

namespace Inprotech.Tests.Web.Search
{
    public class SearchResultSelectorFacts : FactBase
    {
        [Fact]
        public void ReturnsSearchResultWithSelectedItems()
        {
            var list = new List<Dictionary<string, object>>
            {
                new Dictionary<string, object>
                {
                    {"1", new {DebtorKey = 100, CaseKey = 201}},
                    {"RowKey", 1}
                },
                new Dictionary<string, object>
                {
                    {"2", new {DebtorKey = 101, CaseKey = 202}},
                    {"RowKey", 2}
                },
                new Dictionary<string, object>
                {
                    {"3", new {DebtorKey = 103, CaseKey = 205}},
                    {"RowKey", 3}
                }
            };
            var searchResult = new SearchResult {Rows = list, TotalRows = list.Count};
            var fixer = new ReportsControllerFixture();
            var result = fixer.Subject.GetActualSelectedRecords(searchResult, QueryContext.WipOverviewSearch, new[] {3});
            Assert.NotNull(result);
            Assert.Equal(2, result.Rows.Count());
            Assert.Equal(3, result.TotalRows);
        }

        [Fact]
        public void ShouldRaiseAnException()
        {
            var fixer = new ReportsControllerFixture();
            Assert.Throws<ArgumentNullException>(() => fixer.Subject.GetActualSelectedRecords(null, QueryContext.WipOverviewSearch, new[] {3}));
        }

        [Fact]
        public void ShouldReturnUnchangedSearchResultIfRowKeyNotProvided()
        {
            var list = new List<Dictionary<string, object>>
            {
                new Dictionary<string, object>
                {
                    {"1", new {DebtorKey = 100, CaseKey = 201}},
                    {"RowKey", 1}
                },
                new Dictionary<string, object>
                {
                    {"2", new {DebtorKey = 101, CaseKey = 202}},
                    {"RowKey", 2}
                },
                new Dictionary<string, object>
                {
                    {"3", new {DebtorKey = 103, CaseKey = 205}},
                    {"RowKey", 3}
                }
            };
            var searchResult = new SearchResult {Rows = list, TotalRows = list.Count};
            var fixer = new ReportsControllerFixture();
            var result = fixer.Subject.GetActualSelectedRecords(searchResult, QueryContext.CaseSearch, new[] {3});
            Assert.NotNull(result);
            Assert.Equal(3, result.Rows.Count());
            Assert.Equal(3, result.TotalRows);
        }
    }

    public class ReportsControllerFixture : IFixture<SearchResultSelector>
    {
        public ReportsControllerFixture()
        {
            Subject = new SearchResultSelector();
        }

        public SearchResultSelector Subject { get; }
    }
}