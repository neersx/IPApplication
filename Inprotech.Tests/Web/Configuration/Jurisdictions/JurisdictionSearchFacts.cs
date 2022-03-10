using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Jurisdictions;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions
{
    public class JurisdictionSearchFacts
    {
        public class JurisdictionSearchFixture : IFixture<JurisdictionSearch>
        {
            readonly InMemoryDbContext _db;

            public JurisdictionSearchFixture(InMemoryDbContext db)
            {
                _db = db;
                CultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new JurisdictionSearch(db, CultureResolver);
                PopulateCountries();
            }

            public IPreferredCultureResolver CultureResolver { get; set; }
            public JurisdictionSearch Subject { get; }

            void PopulateCountries()
            {
                AddCountry("AU", "Australia", "0");
                AddCountry("BR", "Brazil", "0");
                AddCountry("CN", "China", "0");
                AddCountry("EM", "European Community", "1");
                AddCountry("ZZZ", "DEFAULT FOREIGN COUNTRY", "2");
                AddCountry("CD", "Democractic Republic of Congo", "3");
            }

            void AddCountry(string countryCode, string countryName, string countryType)
            {
                new Country
                {
                    Id = countryCode,
                    Name = countryName,
                    Type = countryType
                }.In(_db);
            }
        }

        public class SearchMethod : FactBase
        {
            [Theory]
            [InlineData("C", 4)]
            [InlineData("VQ", 0)]
            [InlineData("China", 1)]
            [InlineData("vvvqqq", 0)]
            public void SearchReturnsMatchesOnCodeAndName(string query, int expected)
            {
                var j = new JurisdictionSearchFixture(Db);
                var s = new SearchOptions {Text = query};
                var r = j.Subject.Search(s).ToArray();

                Assert.Equal(expected, r.Length);
            }

            [Fact]
            public void ReturnsAllCountriesOrderedByName()
            {
                var j = new JurisdictionSearchFixture(Db);
                var s = new SearchOptions {Text = string.Empty};
                var r = j.Subject.Search(s).ToArray();

                Assert.Equal(6, r.Length);
                Assert.True(r[0].Id == "AU");
                Assert.True(r[1].Id == "BR");
                Assert.True(r[2].Id == "CN");
                Assert.True(r[3].Id == "ZZZ");
                Assert.True(r[4].Id == "CD");
                Assert.True(r[5].Id == "EM");
            }
        }
    }
}