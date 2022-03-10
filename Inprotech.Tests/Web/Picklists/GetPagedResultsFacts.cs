using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class HelperFacts
    {
        public class GetPagedResults
        {
            class TestMatcher
            {
                public string Code { get; set; }
            }

            class TestClass
            {
                public string Code { get; set; }
            }

            class TestPicklistItem
            {
                public TestPicklistItem(string code, string description)
                {
                    Code = code;
                    Description = description;
                }

                public string Code { get; }
                public string Description { get; }
            }

            [Fact]
            public void OrdersByExactMatch()
            {
                var data = new[]
                {
                    new TestMatcher {Code = "def"},
                    new TestMatcher {Code = "abc"},
                    new TestMatcher {Code = "ghi"}
                };

                var results = Helpers.GetPagedResults(data,
                                                      new CommonQueryParameters(),
                                                      x => x.Code, x => null, "ghi").Data
                                     .ToArray();

                Assert.Equal(3, results.Length);
                Assert.Equal(data[2].Code, results[0].Code);
            }

            [Fact]
            public void OrdersByExactMatchThenByProperty()
            {
                var data = new[]
                {
                    new TestMatcher {Code = "abc"},
                    new TestMatcher {Code = "def"},
                    new TestMatcher {Code = "ghi"}
                };

                var results = Helpers.GetPagedResults(data,
                                                      null,
                                                      x => x.Code, x => null, "ghi").Data
                                     .ToArray();

                Assert.Equal(data[2].Code, results[0].Code);
                Assert.Equal(data[0].Code, results[1].Code);
            }

            [Fact]
            public void OrdersByQueryParams()
            {
                var data = new[]
                {
                    new TestClass {Code = "def"},
                    new TestClass {Code = "abc"},
                    new TestClass {Code = "ghi"}
                };

                var queryParams = new CommonQueryParameters
                {
                    SortBy = "Code",
                    SortDir = "desc"
                };

                var results = (dynamic) Helpers.GetPagedResults(data, queryParams, null, x => null, null).Data;

                Assert.Equal(data[2].Code, results[0].Code);
                Assert.Equal(data[1].Code, results[2].Code);
            }

            [Fact]
            public void PicklistSorting()
            {
                var item1 = new TestPicklistItem("a", "b");
                var item2 = new TestPicklistItem("absolutely", "random");
                var item3 = new TestPicklistItem("relatively", "wrong");
                var item4 = new TestPicklistItem("absolutely", "random");
                var item5 = new TestPicklistItem("actually", "adorable");
                var item6 = new TestPicklistItem("rediculously", "awesome");
                var item7 = new TestPicklistItem("nowere", "near");
                var item8 = new TestPicklistItem("nowere", "far");
                var item9 = new TestPicklistItem("b", "a");

                var testData = new List<TestPicklistItem>
                {
                    item1,
                    item2,
                    item3,
                    item4,
                    item5,
                    item6,
                    item7,
                    item8,
                    item9
                };

                var results = Helpers.GetPagedResults(testData,
                                                      new CommonQueryParameters(),
                                                      x => x.Code, x => x.Description, "A").Data
                                     .ToArray();

                Assert.Equal(9, results.Length);

                Assert.Equal(item9, results[0]); // exact match on description
                Assert.Equal(item1, results[1]); // exact match on code
                Assert.Equal(item5, results[2]); // code starts with
                Assert.Equal("absolutely", results[3].Code);
                Assert.Equal("absolutely", results[4].Code);
                Assert.Equal(item6, results[5]); // description starts with
                Assert.Equal(item3, results[6]); // code contains
                Assert.Equal(item8, results[7]); // description contains
                Assert.Equal(item7, results[8]);
            }

            [Fact]
            public void SearchOrderOverridenWhenSearching()
            {
                var data = new[]
                {
                    new TestMatcher {Code = "abc"},
                    new TestMatcher {Code = "def"},
                    new TestMatcher {Code = "ghi"}
                };

                var queryParams = new CommonQueryParameters
                {
                    SortBy = "Code",
                    SortDir = "asc"
                };

                var results = Helpers.GetPagedResults(data,
                                                      queryParams,
                                                      x => x.Code, x => null, "ghi").Data
                                     .ToArray();

                Assert.Equal(data[0].Code, results[0].Code);
                Assert.Equal(data[1].Code, results[1].Code);
                Assert.Equal(data[2].Code, results[2].Code);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var data = new[]
                {
                    new TestMatcher {Code = "def"},
                    new TestMatcher {Code = "abc"},
                    new TestMatcher {Code = "ghi"}
                };

                var queryParams = new CommonQueryParameters
                {
                    Skip = 1,
                    Take = 1
                };

                var results = Helpers.GetPagedResults(data, queryParams, null, x => null, null);

                Assert.Single(results.Data);
                Assert.Equal(data[1], results.Data.First());
                Assert.Equal(3, results.Pagination.Total);
            }

            [Fact]
            public void UsesDefaultQueryParams()
            {
                var data = new List<TestClass>();

                for (var i = 0; i < 50; i++) data.Add(new TestClass {Code = Fixture.String("b")});
                var first = new TestClass {Code = "abc"};
                data.Add(first);

                var queryParams = new CommonQueryParameters
                {
                    SortBy = "Code"
                };

                var results = Helpers.GetPagedResults(data, queryParams, null, x => null, null);

                Assert.Equal(50, results.Data.Count());
                Assert.Equal(first, results.Data.First());
                Assert.Equal(data.Count, results.Pagination.Total);
            }
        }
    }
}