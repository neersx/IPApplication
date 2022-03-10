using Inprotech.Tests.Fakes;
using Inprotech.Web.Geo;
using InprotechKaizen.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.Geo
{
    public class CountryControllerFacts
    {
        public class ListMethod : FactBase
        {
            public ListMethod()
            {
                new Country("AU", "Australia").In(Db);
                new Country("US", "United States").In(Db);
                new Country("IN", "India").In(Db);
            }

            [Fact]
            public void ShouldReturnAllCountries()
            {
                var results = new CountryController(Db).List(string.Empty);

                Assert.Equal(3, results.Length);
                Assert.Equal("AU", results[0].Key);
                Assert.Equal("AU", results[0].Id);
                Assert.Equal("Australia", results[0].Name);
            }

            [Fact]
            public void ShouldReturnCountryForInput()
            {
                var results = new CountryController(Db).List("a");

                Assert.Equal(1, results.Length);
                Assert.Equal("AU", results[0].Key);
            }

            [Fact]
            public void ShouldReturnCountryForInputKey()
            {
                var results = new CountryController(Db).List("us");

                Assert.Equal(1, results.Length);
                Assert.Equal("US", results[0].Key);
            }
        }
    }
}