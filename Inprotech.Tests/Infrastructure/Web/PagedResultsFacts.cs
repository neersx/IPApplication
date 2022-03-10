using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Web
{
    public class PagedResultsFacts
    {
        public class AsPagedResults
        {
            [Fact]
            public void ReturnsEmptyArrayAndReportZero()
            {
                var result = new List<dynamic>().AsPagedResults(new CommonQueryParameters());

                Assert.Empty(result.Data);
                Assert.Equal(0, result.Pagination.Total);
            }

            [Fact]
            public void SkipsAndTakesAndReturnsTotal()
            {
                var items = new List<dynamic>();
                for (var i = 0; i <= 15; i++) items.Add(new { });

                var result = items.AsPagedResults(new CommonQueryParameters
                {
                    Skip = 5,
                    Take = 10
                });

                Assert.Equal(10, result.Data.Count());
                Assert.Equal(items.ElementAt(5), result.Data.ToArray()[0]);
                Assert.Equal(16, result.Pagination.Total);
            }
        }

        public class Items
        {
            public class ItemKind
            {
            }

            [Fact]
            public void ReturnsEmptyArrayAndReportZero()
            {
                var pagedResults = new List<ItemKind>().AsPagedResults(new CommonQueryParameters());

                Assert.Equal(pagedResults.Data.Cast<ItemKind>(), pagedResults.Items<ItemKind>());
            }
        }
    }
}