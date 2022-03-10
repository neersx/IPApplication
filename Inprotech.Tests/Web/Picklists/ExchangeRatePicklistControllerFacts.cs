using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ExchangeRatePicklistControllerFacts : FactBase
    {
        public class ExchangeRateMethod : FactBase
        {
            [Theory]
            [InlineData("rate 1")]
            [InlineData("code 2")]
            public void SearchForExactAndContainsMatchOnDescription(string searchText)
            {
                var f = new ExchangeRatePicklistControllerFixture(Db);

                new ExchangeRateSchedule { ExchangeScheduleCode = Fixture.String(), Description = "exchange rate 1"}.In(Db);
                new ExchangeRateSchedule { ExchangeScheduleCode = "exchange code 2", Description = "exchange rate 2"}.In(Db);
                new ExchangeRateSchedule { ExchangeScheduleCode = Fixture.String(), Description = "exchange rate 3"}.In(Db);

                var r = f.Subject.ExchangeRateSchedule(null, searchText);

                var j = r.Data.OfType<ExchangeRateSchedulePicklistController.ExchangeRateSchedulePicklistItem>().ToArray();

                Assert.Equal(1, j.Length);
            }

            [Fact]
            public void ReturnsRatesContainingSearchStringOrderedByDescription()
            {
                var f = new ExchangeRatePicklistControllerFixture(Db);

                var record1 = new ExchangeRateSchedule { ExchangeScheduleCode = Fixture.String(), Description = "abc"}.In(Db);
                new ExchangeRateSchedule { ExchangeScheduleCode = Fixture.String(), Description = "daf"}.In(Db);
                var record3 = new ExchangeRateSchedule {ExchangeScheduleCode = Fixture.String(),  Description = "xaz"}.In(Db);

                var r = f.Subject.ExchangeRateSchedule(null, "a");

                var j = r.Data.OfType<ExchangeRateSchedulePicklistController.ExchangeRateSchedulePicklistItem>().ToArray();

                Assert.Equal(3, j.Length);
                Assert.Equal(record1.Description, j.First().Description);
                Assert.Equal(record3.Description, j.Last().Description);
            }
        }
    }

    public class ExchangeRatePicklistControllerFixture : IFixture<ExchangeRateSchedulePicklistController>
    {
        public ExchangeRatePicklistControllerFixture(InMemoryDbContext db)
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            Subject = new ExchangeRateSchedulePicklistController(db, preferredCultureResolver);
        }

        public ExchangeRateSchedulePicklistController Subject { get; }
    }
}