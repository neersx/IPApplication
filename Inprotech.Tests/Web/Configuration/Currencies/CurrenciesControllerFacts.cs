using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Currencies;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;
using static Inprotech.Web.Configuration.Currencies.CurrenciesService;

namespace Inprotech.Tests.Web.Configuration.Currencies
{
    public class CurrenciesControllerFacts
    {
        public class CurrenciesControllerFixture : IFixture<CurrenciesController>
        {
            public CurrenciesControllerFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                Currencies = Substitute.For<ICurrencies>();

                Subject = new CurrenciesController(db, TaskSecurityProvider, PreferredCultureResolver, Currencies);
                CommonQueryParameters = CommonQueryParameters.Default;
                CommonQueryParameters.SortBy = null;
                CommonQueryParameters.SortDir = null;
            }

            public ICommonQueryService CommonQueryService { get; set; }
            public CommonQueryParameters CommonQueryParameters { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public ICurrencies Currencies { get; set; }
            public CurrenciesController Subject { get; set; }
        }

        public class ViewData : FactBase
        {
            [Fact]
            public void ShouldReturnAppropriatePermission()
            {
                var f = new CurrenciesControllerFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Modify).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Delete).Returns(false);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Create).Returns(true);

                var res = f.Subject.ViewData();

                Assert.Equal(res.CanAdd, true);
                Assert.Equal(res.CanDelete, false);
                Assert.Equal(res.CanEdit, true);
            }
        }

        public class GetCurrencies : FactBase
        {
            [Fact]
            public void SearchForExactAndContainsMatchOnDescription()
            {
                var f = new CurrenciesControllerFixture(Db);
                var searchOptions = new SearchOptions { Text = "Currency 1" };

                var c1 = new Currency {Id = Fixture.String(), Description = "Currency 1"}.In(Db);
                new Currency {Id = "Aud", Description = "Currency 2"}.In(Db);
                new Currency {Id = Fixture.String(), Description = "Currency 3"}.In(Db);
                new ExchangeRateHistory {Id = c1.Id, DateChanged = Fixture.Date("2002-01-01")}.In(Db);

                var r = f.Subject.GetCurrencies(searchOptions);

                var j = r.Data.OfType<dynamic>().ToArray();

                Assert.Equal(1, j.Length);
                Assert.True(j[0].HasHistory);
            }

            [Fact]
            public void SearchReturnAllWhenNoSearchTextIsGiven()
            {
                var f = new CurrenciesControllerFixture(Db);
                var searchOptions = new SearchOptions();

                new Currency { Id = Fixture.String(), Description = "Currency 1" }.In(Db);
                new Currency { Id = "Aud", Description = "Currency 2" }.In(Db);
                new Currency { Id = Fixture.String(), Description = "Currency 3" }.In(Db);

                var r = f.Subject.GetCurrencies(searchOptions);

                var j = r.Data.OfType<dynamic>().ToArray();

                Assert.Equal(3, j.Length);
            }

            public class GetCurrencyDetails : FactBase
            {
                [Fact]
                public async Task ShouldGetCurrency()
                {
                    var f = new CurrenciesControllerFixture(Db);

                    await f.Subject.GetCurrencyDetails("Aud");
                    await f.Currencies.Received(1).GetCurrencyDetails("Aud");
                }
            }

            public class SaveCurrency : FactBase
            {
                [Fact]
                public async Task ShouldThrowErrorInAddWhenDataNotExist()
                {
                    var f = new CurrenciesControllerFixture(Db);
                    var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                    {
                        await f.Subject.AddCurrency(null);
                    });
                    Assert.IsType<ArgumentNullException>(exception);
                }

                [Fact]
                public async Task ShouldSaveCurrency()
                {
                    var f = new CurrenciesControllerFixture(Db);
                    var data = new CurrencyModel();
                    f.Currencies.SubmitCurrency(data).Returns("ABC");
                    var result = await f.Subject.AddCurrency(data);
                    Assert.Equal(result, "ABC");
                    await f.Currencies.Received(1).SubmitCurrency(data);
                }

                [Fact]
                public async Task ShouldUpdateCurrency()
                {
                    var f = new CurrenciesControllerFixture(Db);
                    var data = new CurrencyModel()
                    {
                        Id = Fixture.String(),
                        CurrencyCode = Fixture.String(),
                        CurrencyDescription = Fixture.String(),
                        SellFactor = Fixture.Integer(),
                        BuyFactor = Fixture.Integer(),
                        BankRate = 1,
                        RoundedBillValues = 2

                    };
                    f.Currencies.SubmitCurrency(data).Returns("UPD");
                    var result = await f.Subject.UpdateCurrency(data);
                    Assert.Equal(result, "UPD");
                    await f.Currencies.Received(1).SubmitCurrency(data);
                }

                [Fact]
                public async Task ShouldThrowErrorInUpdateWhenDataNotExist()
                {
                    var f = new CurrenciesControllerFixture(Db);
                    var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                    {
                        await f.Subject.UpdateCurrency(null);
                    });
                    Assert.IsType<ArgumentNullException>(exception);
                }
            }

        }

        public class DeleteCurrency : FactBase
        {
            [Fact]
            public async Task ShouldDeleteCurrencies()
            {
                var f = new CurrenciesControllerFixture(Db);
                f.Currencies.DeleteCurrencies(Arg.Any<CurrenciesDeleteRequestModel>()).Returns(new CurrenciesDeleteResponseModel { Message = "success" });
                var response = await f.Subject.DeleteCurrencies(new CurrenciesDeleteRequestModel());
                Assert.Equal("success", response.Message);
                await f.Currencies.Received(1).DeleteCurrencies(Arg.Any<CurrenciesDeleteRequestModel>());
            }

            [Fact]
            public async Task ShouldReturnError()
            {
                var f = new CurrenciesControllerFixture(Db);
                f.Currencies.DeleteCurrencies(Arg.Any<CurrenciesDeleteRequestModel>()).Throws(new HttpResponseException(HttpStatusCode.NotFound));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => { await f.Subject.DeleteCurrencies(new CurrenciesDeleteRequestModel()); });
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }

        public class GetExchangeRateHistory : FactBase
        {
            [Fact]
            public void ShouldReturnExchangeRateHistory()
            {
                var f = new CurrenciesControllerFixture(Db);
                var e1 = new ExchangeRateHistory {Id = "IND", DateChanged = Fixture.Date("2002-01-02"), BankRate = Fixture.Decimal(), SellFactor = Fixture.Decimal(), BuyRate = Fixture.Decimal(), SellRate = Fixture.Decimal(), BuyFactor = Fixture.Decimal()}.In(Db);
                var e2 = new ExchangeRateHistory {Id = "IND", DateChanged = Fixture.Date("2002-01-03"), BankRate = Fixture.Decimal(), SellFactor = Fixture.Decimal(), BuyRate = Fixture.Decimal(), SellRate = Fixture.Decimal(), BuyFactor = Fixture.Decimal()}.In(Db);
                var e3 = new ExchangeRateHistory {Id = "IND", DateChanged = Fixture.Date("2002-01-01"), BankRate = Fixture.Decimal(), SellFactor = Fixture.Decimal(), BuyRate = Fixture.Decimal(), SellRate = Fixture.Decimal(), BuyFactor = Fixture.Decimal()}.In(Db);

                var results = f.Subject.GetExchangeRateHistory("IND", new CommonQueryParameters());
                var j = results.Data.OfType<dynamic>().ToArray();
                Assert.Equal(3, j.Length);
                Assert.Equal(e2.DateChanged, j[0].EffectiveDate);
                Assert.Equal(e1.DateChanged, j[1].EffectiveDate);
                Assert.Equal(e3.DateChanged, j[2].EffectiveDate);
            }

            [Fact]
            public void ShouldThrowArgumentNullExceptionWhenIdNotFound()
            {
                var f = new CurrenciesControllerFixture(Db);
                var exception = Assert.Throws<ArgumentNullException>(() => { f.Subject.GetExchangeRateHistory(null, new CommonQueryParameters());});
                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class GetCurrencyDesc : FactBase
        {
            [Fact]
            public async Task ShouldThrowArgumentNullExceptionWhenIdNotFound()
            {
                var f = new CurrenciesControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.GetCurrencyDesc(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldReturnCurrencyDesc()
            {
                var f = new CurrenciesControllerFixture(Db);
                var c = new Currency {Id = Fixture.String(), Description = "Currency 1"}.In(Db);
                var result = await f.Subject.GetCurrencyDesc(c.Id);
                Assert.Equal(c.Description, result);
            }
        }
    }
}