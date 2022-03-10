using System.Linq;
using Inprotech.Web.BulkCaseImport;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class FieldDetailsFacts
    {
        public class RelatedCasesSuffixesProperty : FactBase
        {
            [Fact]
            public void FindsUniqueSuffixesForRelatedCases()
            {
                var fields = new[] {"Priority Country - A", "Priority Number - B", "Priority Date - A", "Parent Date - B", "Parent Country - A"};

                var f = new FieldDetails(fields);

                var r = f.RelatedCasesSuffixes;

                Assert.Equal(3, r.Count);
                Assert.Contains(string.Empty, r);
                Assert.Contains(" - A", r);
                Assert.Contains(" - B", r);
            }

            [Fact]
            public void RelatedCasesSuffixesAlwaysContainsBlankItem()
            {
                var fields = new[] {"Priority Country", "Priority Number", "Priority Date", "Parent Date", "Parent Country"};

                var f = new FieldDetails(fields);

                var r = f.RelatedCasesSuffixes;

                Assert.Single(r);
                Assert.Contains(string.Empty, r);
            }
        }

        public class GetCustomColumnsOnlyMethod : FactBase
        {
            [Fact]
            public void ReturnsCustomColumnsOnly()
            {
                var f = new FieldDetails(new[] {"Property Type", "Country", "Case Category", "A New Column"});

                var customColumnsOnly = f.GetCustomColumnsOnly(new JObject
                {
                    {"Property Type", "patent"},
                    {"Country", "AU"},
                    {"Case Category", "category"},
                    {"A New Column", "new data"}
                });

                Assert.NotEmpty(customColumnsOnly);
                Assert.Single(customColumnsOnly.Children());
                Assert.Equal("A New Column", customColumnsOnly.Select(_ => ((JProperty) _).Name).Single());
            }
        }
    }
}