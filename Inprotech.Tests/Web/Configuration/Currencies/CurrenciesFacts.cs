using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Currencies;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;
using static Inprotech.Web.Configuration.Currencies.CurrenciesService;

namespace Inprotech.Tests.Web.Configuration.Currencies
{
    public class CurrenciesFacts
    {
        public class CurrenciesFixture : IFixture<CurrenciesService>
        {
            public CurrenciesFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new CurrenciesService(db, PreferredCultureResolver);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public CurrenciesService Subject { get; set; }

            public class Delete : FactBase
            {
                [Fact]
                public async Task ShouldThrowErrorWhenIdNotExist()
                {
                    var f = new CurrenciesFixture(Db);
                    var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                    {
                        await f.Subject.DeleteCurrencies(new CurrenciesDeleteRequestModel());
                    });
                    Assert.IsType<ArgumentNullException>(exception);
                }

                [Fact]
                public async Task ShouldDeleteCurrencies()
                {
                    var f = new CurrenciesFixture(Db);
                    var currency = new Currency { Id = Fixture.String(), Description = "Currency 1" }.In(Db);
                    new ExchangeRateHistory(currency).In(Db);

                    var result = await f.Subject.DeleteCurrencies(new CurrenciesDeleteRequestModel { Ids = new List<string> { currency.Id } });
                    Assert.False(result.HasError);
                    Assert.Empty(Db.Set<Currency>());
                    Assert.Empty(Db.Set<ExchangeRateHistory>());
                }
            }

            public class GetCurrencyDetail : FactBase
            {
                [Fact]
                public async Task GetCurrencyDetails()
                {
                    var f = new CurrenciesFixture(Db);
                    var k1 = new Currency() { Id = "Abc", Description = "Code Abc", DateChanged = DateTime.Now }.In(Db);
                    var result = await f.Subject.GetCurrencyDetails(k1.Id);
                    Assert.Equal(k1.Id, result.CurrencyCode);

                    var result1 = await f.Subject.GetCurrencyDetails(k1.Id);
                    Assert.Equal(k1.Id, result1.CurrencyCode);
                }

                [Fact]
                public async Task ShouldThrowErrorWhenIdNotExist()
                {
                    new Currency() { Id = "Abc", Description = "Code Abc", DateChanged = DateTime.Now }.In(Db);
                    var f = new CurrenciesFixture(Db);
                    var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => { await f.Subject.GetCurrencyDetails("TST"); });
                    Assert.IsType<HttpResponseException>(exception);
                }
            }

            public class SubmitCurrency : FactBase
            {
                [Fact]
                public async Task ShouldThrowErrorWhenIdNoModelPassed()
                {
                    var f = new CurrenciesFixture(Db);
                    var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.SubmitCurrency(null); });
                    Assert.IsType<ArgumentNullException>(exception);
                }

                [Fact]
                public async Task ShouldEditCurrency()
                {
                    var f = new CurrenciesFixture(Db);
                    var c1 = new Currency() { Id = "Abc", Description = Fixture.String(), DateChanged = DateTime.Now }.In(Db);
                    var request = new CurrencyModel()
                    {
                        Id = c1.Id,
                        CurrencyDescription = Fixture.String()
                    };

                    var result = await f.Subject.SubmitCurrency(request);
                    Assert.Equal(c1.Id, result);
                    Assert.Equal(request.CurrencyDescription, c1.Description);
                }

                [Fact]
                public async Task ShouldAddCurrency()
                {
                    var f = new CurrenciesFixture(Db);
                    var c1 = new Currency() { Id = Fixture.String(), Description = Fixture.String(), DateChanged = DateTime.Now }.In(Db);
                    new ExchangeRateHistory(c1).In(Db);
                    var id = Fixture.String();
                    var request = new CurrencyModel()
                    {
                        Id = id,
                        CurrencyDescription = Fixture.String(),
                        DateChanged = DateTime.Now,
                        SellRate = 1,
                        BankRate = 1,
                        SellFactor = 1
                    };

                    var result = await f.Subject.SubmitCurrency(request);
                    var k1 = Db.Set<Currency>().First(_ => _.Id == result);
                    var e1 = Db.Set<ExchangeRateHistory>().First(_ => _.Id == result);

                    Assert.Equal(request.Id, k1.Id);
                    Assert.Equal(id, result);
                    Assert.Equal(e1.Id, result);
                }
            }
        }
    }
}
