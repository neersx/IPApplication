using Inprotech.Tests.Fakes;
using Inprotech.Web.Lists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.Web.Lists
{
    public class StatesControllerFacts
    {
        public class StatesControllerFixture : IFixture<StatesController>
        {
            readonly InMemoryDbContext _db;

            public StatesControllerFixture(InMemoryDbContext db)
            {
                _db = db;
            }

            public StatesController Subject => new StatesController(_db);
        }

        public class GetMethod : FactBase
        {
            public GetMethod()
            {
                _fixture = new StatesControllerFixture(Db);
                BuildStates();
            }

            readonly StatesControllerFixture _fixture;

            void BuildStates()
            {
                var au = new Country("AU", "australia").In(Db);
                var us = new Country("US", "United States").In(Db);

                new State("MEL", "Melbourne", au).In(Db);
                new State("NSW", "New South Wales", au).In(Db);
                new State("AL", "Alaska", us).In(Db);
            }

            [Fact]
            public void ShouldReturnAllStates()
            {
                var results = _fixture.Subject.Get(string.Empty);

                Assert.Equal(3, results.Length);
                Assert.Equal("AL", results[0].Code);
                Assert.Equal("Alaska", results[0].Name);
                Assert.Equal("US", results[0].CountryCode);
                Assert.Equal("United States", results[0].CountryName);
            }

            [Fact]
            public void ShouldReturnStatesForCountry()
            {
                var results = _fixture.Subject.Get(string.Empty, "AU");

                Assert.Equal(2, results.Length);
            }

            [Fact]
            public void ShouldReturnStatesForInput()
            {
                var results = _fixture.Subject.Get("a");

                Assert.Equal(1, results.Length);
                Assert.Equal("AL", results[0].Code);
            }

            [Fact]
            public void ShouldReturnStatesForInputCode()
            {
                var results = _fixture.Subject.Get("ns");

                Assert.Equal(1, results.Length);
                Assert.Equal("NSW", results[0].Code);
            }
        }
    }
}