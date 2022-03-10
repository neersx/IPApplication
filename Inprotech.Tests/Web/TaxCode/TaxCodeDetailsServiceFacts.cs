using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.TaxCode;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.TaxCode
{
    public class TaxCodeDetailsServiceFacts
    {
        public class GetTaxCodeDetails : FactBase
        {
            readonly IPreferredCultureResolver _preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            [Fact]
            public async Task ShouldReturnNullIfTaxCodeNotFound()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());
                var f = new TaxCodeDetailServiceFixture(Db);
                var result = await f.Subject.GetTaxCodeDetails(Fixture.Integer(), cultureResolver.ToString());

                Assert.Equal(null, result);
            }

            [Fact]
            public async Task ReturnsTheTaxCodeDetails()
            {
                var taxCode = new TaxRate("T2") { Description = Fixture.String() }.In(Db);
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());
                var f = new TaxCodeDetailServiceFixture(Db);

                var result = await f.Subject.GetTaxCodeDetails(taxCode.Id, cultureResolver.ToString());

                Assert.NotNull(result);
                Assert.Equal(result.Description, taxCode.Description);
                Assert.Equal(result.TaxCode, taxCode.Code);
            }
        }

        public class GetTaxRateDetails : FactBase
        {
            readonly IPreferredCultureResolver _preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            [Fact]
            public async Task ShouldReturnNullIfTaxRateNotFound()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());
                var f = new TaxCodeDetailServiceFixture(Db);
                var result = await f.Subject.GetTaxRateDetails(Fixture.Integer(), cultureResolver.ToString());

                Assert.Equal(0, result.Length);
            }

            [Fact]
            public async Task ReturnsTheTaxRateDetails()
            {
                new Country("1", "Aus").In(Db);
                new TaxRatesCountry { TaxCode = "T2", CountryId = "1", EffectiveDate = Fixture.Date(), Rate = Fixture.Decimal(), TaxRateCountryId = Fixture.Integer() }.In(Db);
                var taxCode = new TaxRate("T2") { Description = Fixture.String() }.In(Db);
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());
                var f = new TaxCodeDetailServiceFixture(Db);

                var result = await f.Subject.GetTaxRateDetails(taxCode.Id, cultureResolver.ToString());

                Assert.NotNull(result);
                Assert.Equal(1, result.Length);
            }
        }
    }

    internal class TaxCodeDetailServiceFixture : IFixture<ITaxCodeDetailService>
    {
        public TaxCodeDetailServiceFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            DateFunc = Substitute.For<Func<DateTime>>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            DateFunc().Returns(Fixture.TodayUtc());

            Subject = new TaxCodeDetailService(db);
        }

        public ISecurityContext SecurityContext { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public Func<DateTime> DateFunc { get; set; }
        public ITaxCodeDetailService Subject { get; }
    }
}