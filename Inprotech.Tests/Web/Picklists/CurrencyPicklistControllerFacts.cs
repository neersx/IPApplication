using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class CurrencyPicklistControllerFacts : FactBase
    {
        public class CurrencyMethod : FactBase
        {
            [Theory]
            [InlineData("Currency 1")]
            [InlineData("Aud")]
            public void SearchForExactAndContainsMatchOnDescription(string searchText)
            {
                var f = new CurrencyPicklistControllerFixture(Db);

                new InprotechKaizen.Model.Cases.Currency {Id = Fixture.String(), Description = "Currency 1"}.In(Db);
                new InprotechKaizen.Model.Cases.Currency {Id = "Aud", Description = "Currency 2"}.In(Db);
                new InprotechKaizen.Model.Cases.Currency {Id = Fixture.String(), Description = "Currency 3"}.In(Db);

                var r = f.Subject.Currency(null, searchText);

                var j = r.Data.OfType<Currency>().ToArray();

                Assert.Equal(1, j.Length);
            }

            [Fact]
            public void ReturnsRatesContainingSearchStringOrderedByDescription()
            {
                var f = new CurrencyPicklistControllerFixture(Db);

                var record1 = new InprotechKaizen.Model.Cases.Currency {Id = Fixture.String(), Description = "abc"}.In(Db);
                new InprotechKaizen.Model.Cases.Currency {Id = Fixture.String(), Description = "daf"}.In(Db);
                var record3 = new InprotechKaizen.Model.Cases.Currency {Id = Fixture.String(),  Description = "xaz"}.In(Db);

                var r = f.Subject.Currency(null, "a");

                var j = r.Data.OfType<Currency>().ToArray();

                Assert.Equal(3, j.Length);
                Assert.Equal(record1.Description, j.First().Description);
                Assert.Equal(record3.Description, j.Last().Description);
            }
        }
    }

    public class CurrencyPicklistControllerFixture : IFixture<CurrencyPicklistController>
    {
        public CurrencyPicklistControllerFixture(InMemoryDbContext db)
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            Subject = new CurrencyPicklistController(db, preferredCultureResolver);
        }

        public CurrencyPicklistController Subject { get; }
    }
}