using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.ExchangeRateVariations;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ExchangeRateVariations
{
    public class ExchangeRateVariationsFacts
    {
        public class ExchangeRateVariationsFixture : IFixture<Inprotech.Web.Configuration.ExchangeRateVariations.ExchangeRateVariations>
        {
            public ExchangeRateVariationsFixture(InMemoryDbContext db)
            {
                Db = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new Inprotech.Web.Configuration.ExchangeRateVariations.ExchangeRateVariations(db, PreferredCultureResolver);
            }
            InMemoryDbContext Db { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public Inprotech.Web.Configuration.ExchangeRateVariations.ExchangeRateVariations Subject { get; set; }

            public ExchangeRateVariationsFixture WithNormalValues(out ExchangeRateVariation exVar)
            {
                var currency = new Currency("ABC").In(Db);
                var ct = new CaseTypeBuilder().Build().In(Db);
                var country = new CountryBuilder().Build().In(Db);
                exVar = new ExchangeRateVariation { Currency = currency, CurrencyCode = currency.Id, CaseType = ct, CaseTypeCode = ct.Code, Country = country, CountryCode = country.Id, EffectiveDate = Fixture.Date(), SellFactor = Fixture.Decimal() }.In(Db);
                return this;
            }
            public ExchangeRateVariationsFixture WithValidValues(out ExchangeRateVariation exVar, out string categoryDescription, out string subTypeDescription, out string stDesc)
            {
                var currency = new Currency("ABC").In(Db);
                var ct = new CaseTypeBuilder().Build().In(Db);
                var country = new CountryBuilder().Build().In(Db);
                var propertyType = new PropertyTypeBuilder().Build().In(Db);
                var caseCategory = new CaseCategoryBuilder { CaseTypeId = ct.Code }.Build().In(Db);
                var st = new SubTypeBuilder().Build().In(Db);
                stDesc = st.Name;
                exVar = new ExchangeRateVariation { Currency = currency, CurrencyCode = currency.Id, CaseType = ct, CaseTypeCode = ct.Code, Country = country, CountryCode = country.Id, PropertyTypeCode = propertyType.Code }.In(Db);
                new ValidPropertyBuilder
                {
                    CountryCode = exVar.CountryCode,
                    CountryName = exVar.Country.Name,
                    PropertyTypeId = exVar.PropertyTypeCode,
                    PropertyTypeName = propertyType.Name
                }.Build().In(Db);

                var category = new ValidCategoryBuilder
                {
                    Country = exVar.Country,
                    PropertyType = propertyType,
                    CaseCategory = caseCategory,
                    CaseType = ct
                }.Build().In(Db);
                exVar.CaseCategoryCode = category.CaseCategoryId;
                categoryDescription = category.CaseCategoryDesc;

                var subType = new ValidSubTypeBuilder
                {
                    Country = exVar.Country,
                    PropertyType = propertyType,
                    SubType = st,
                    CaseType = ct,
                    ValidCategory = category
                }.Build().In(Db);
                exVar.SubtypeCode = subType.SubtypeId;
                subTypeDescription = subType.SubTypeDescription;
                return this;
            }
        }

        public class GetExchangeRateVariations : FactBase
        {
            [Fact]
            public void ShouldThrowErrorWhenFilterNotExist()
            {
                var f = new ExchangeRateVariationsFixture(Db);
                var exception = Assert.Throws<ArgumentNullException>(() => { f.Subject.GetExchangeRateVariations(null); });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public void ShouldReturnResultsForFilter()
            {
                var f = new ExchangeRateVariationsFixture(Db)
                    .WithNormalValues(out var exVar1);

                var filter = new ExchangeRateVariationsFilterModel
                {
                    IsExactMatch = true,
                    CountryCode = exVar1.CountryCode
                };
                var r = f.Subject.GetExchangeRateVariations(filter).ToArray();
                Assert.Equal(1, r.Length);
                Assert.Equal(exVar1.Id, r[0].Id);
                Assert.Equal(exVar1.Currency.Description, r[0].Currency);
                Assert.Equal(exVar1.CaseType.Name, r[0].CaseType);
                Assert.Equal(string.Empty, r[0].PropertyType);
                Assert.Equal(string.Empty, r[0].CaseCategory);
                Assert.Equal(string.Empty, r[0].SubType);
                Assert.Equal(exVar1.EffectiveDate, r[0].EffectiveDate);
                Assert.Equal(exVar1.SellFactor, r[0].SellFactor);
                Assert.Null(r[0].SellRate);
            }

            [Fact]
            public void ShouldReturnResultsForFilterWithExactMatch()
            {
                var f = new ExchangeRateVariationsFixture(Db)
                        .WithNormalValues(out _)
                        .WithValidValues(out var exVar2, out var category, out var subType, out string stDesc);
                var exVar3 = new ExchangeRateVariation { Currency = exVar2.Currency, CurrencyCode = exVar2.Currency.Id, CaseType = exVar2.CaseType, CaseTypeCode = exVar2.CaseTypeCode, Country = exVar2.Country, CountryCode = exVar2.CountryCode, EffectiveDate = Fixture.Date(), SubtypeCode = exVar2.SubtypeCode }.In(Db);

                var filter = new ExchangeRateVariationsFilterModel
                {
                    IsExactMatch = true,
                    CurrencyCode = exVar2.CurrencyCode,
                    CountryCode = exVar2.CountryCode,
                    CaseType = exVar2.CaseTypeCode
                };
                var r = f.Subject.GetExchangeRateVariations(filter).ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal(exVar2.Id, r[0].Id);
                Assert.Equal(exVar2.Currency.Description, r[0].Currency);
                Assert.Equal(exVar2.CaseType.Name, r[0].CaseType);
                Assert.Equal(category, r[0].CaseCategory);
                Assert.Equal(subType, r[0].SubType);
                Assert.Equal(exVar2.EffectiveDate, r[0].EffectiveDate);
                Assert.Equal(exVar3.Id, r[1].Id);
                Assert.Equal(stDesc, r[1].SubType); // To check normal subtype desc when valid subtype not exist
            }

            [Fact]
            public void ShouldReturnResultsForFilterWithBestMatch()
            {
                var f = new ExchangeRateVariationsFixture(Db)
                        .WithNormalValues(out _)
                        .WithValidValues(out var exVar2, out _, out _, out _);
                var exVar3 = new ExchangeRateVariation { Currency = exVar2.Currency, CurrencyCode = exVar2.Currency.Id, CaseType = exVar2.CaseType, CaseTypeCode = exVar2.CaseTypeCode, Country = exVar2.Country, CountryCode = exVar2.CountryCode, EffectiveDate = Fixture.Date() }.In(Db);

                var filter = new ExchangeRateVariationsFilterModel
                {
                    IsExactMatch = false,
                    CurrencyCode = exVar2.CurrencyCode,
                    CountryCode = exVar2.CountryCode,
                    CaseType = exVar2.CaseTypeCode
                };
                var r = f.Subject.GetExchangeRateVariations(filter).ToArray();
                Assert.Equal(1, r.Length);
                Assert.Equal(exVar3.Id, r[0].Id);
                Assert.Equal(exVar3.Currency.Description, r[0].Currency);
                Assert.Equal(exVar3.CaseType.Name, r[0].CaseType);
                Assert.Equal(string.Empty, r[0].CaseCategory);
                Assert.Equal(string.Empty, r[0].SubType);
                Assert.Equal(exVar3.EffectiveDate, r[0].EffectiveDate);
            }
        }

        public class Delete : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorWhenIdNotExist()
            {
                var f = new ExchangeRateVariationsFixture(Db);
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.Delete(new DeleteRequestModel());
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldDeleteExchangeRateVariations()
            {
                var f = new ExchangeRateVariationsFixture(Db);
                var o1 = new ExchangeRateVariation{CurrencyCode = "ABX"}.In(Db);

                var result = await f.Subject.Delete(new DeleteRequestModel {Ids = new List<int> {o1.Id}});
                Assert.False(result.HasError);
            }
        }

        public class GetExchangeRateVariationDetail : FactBase
        {
            [Fact]
            public async Task GetExchangeRateVariationDetails()
            {
                var f = new ExchangeRateVariationsFixture(Db)
                    .WithNormalValues(out var exVar1);
                var exVar = new ExchangeRateVariation { Currency = exVar1.Currency, CurrencyCode = exVar1.Currency.Id, CaseType = exVar1.CaseType, CaseTypeCode = exVar1.CaseTypeCode, Country = exVar1.Country, CountryCode = exVar1.CountryCode, EffectiveDate = Fixture.Date() }.In(Db);

                var result = await f.Subject.GetExchangeRateVariationDetails(exVar.Id);
                Assert.Equal(exVar.Id, result.Id);

                var result1 = await f.Subject.GetExchangeRateVariationDetails(exVar.Id);
                Assert.Equal(exVar.Id, result1.Id);
            }

            [Fact]
            public async Task ShouldThrowErrorWhenIdNotExist()
            {
                new ExchangeRateVariation() { Id = Fixture.Integer(), EffectiveDate = DateTime.Now }.In(Db);
                var f = new ExchangeRateVariationsFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => { await f.Subject.GetExchangeRateVariationDetails(Fixture.Integer()); });
                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class ExchangeRateVariationValidation : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorWhenIdNoModelPassed()
            {
                var f = new ExchangeRateVariationsFixture(Db);
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.ValidateDuplicateExchangeVariation(null); });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldValidateExchangeRateVariation()
            {
                var f = new ExchangeRateVariationsFixture(Db)
                    .WithNormalValues(out _);
                new ExchangeRateVariation() { Id = Fixture.Integer(), CurrencyCode = "DUP", SellRate = 1, EffectiveDate = Fixture.Date() }.In(Db);

                var request = new ExchangeRateVariationRequest() { CurrencyCode = "DUP", SellRate = 1, EffectiveDate = Fixture.Date() };
                var result = await f.Subject.ValidateDuplicateExchangeVariation(request);
                Assert.Equal("currencyCode", result.Field);
            }
        }

        public class SubmitExchangeRateVariation : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorWhenIdNoModelPassed()
            {
                var f = new ExchangeRateVariationsFixture(Db);
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.SubmitExchangeRateVariation(null); });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldEditExchangeRateVariation()
            {
                var f = new ExchangeRateVariationsFixture(Db)
                    .WithNormalValues(out var exVar1);
                var exVar = new ExchangeRateVariation { Currency = exVar1.Currency, CurrencyCode = exVar1.Currency.Id, CaseType = exVar1.CaseType, CaseTypeCode = exVar1.CaseTypeCode, Country = exVar1.Country, CountryCode = exVar1.CountryCode, EffectiveDate = Fixture.Date() }.In(Db);

                var request = new ExchangeRateVariationRequest()
                {
                    Id = exVar.Id,
                    EffectiveDate = DateTime.Now
                };

                var result = await f.Subject.SubmitExchangeRateVariation(request);
                Assert.Equal(exVar.Id, result);
            }

            [Fact]
            public async Task ShouldAddExchangeRateVariation()
            {
                var f = new ExchangeRateVariationsFixture(Db);
                new ExchangeRateVariation() { Id = Fixture.Integer(), EffectiveDate = DateTime.Now }.In(Db);

                var request = new ExchangeRateVariationRequest()
                {
                    Id = null,
                    CurrencyCode = Fixture.String(),
                    CountryCode = Fixture.String(),
                    EffectiveDate = DateTime.Now,
                    SellRate = 1,
                    CaseTypeCode = Fixture.String(),
                    SellFactor = 1
                };

                var result = await f.Subject.SubmitExchangeRateVariation(request);
                var k1 = Db.Set<ExchangeRateVariation>().First(x => x.Id == 1);

                Assert.Equal(1, result);
                Assert.Equal(k1.CountryCode, request.CountryCode);
                Assert.Equal(k1.SellFactor, request.SellFactor);
                Assert.Equal(k1.CaseTypeCode, request.CaseTypeCode);
                Assert.Equal(k1.CurrencyCode, request.CurrencyCode);
            }
        }

    }
}
