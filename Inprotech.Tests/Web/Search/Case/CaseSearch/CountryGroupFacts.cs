using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Search.Case.CaseSearch;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class CountryGroupFacts : FactBase
    {
        public CountryGroupFacts()
        {
            _countryGroup = new CountryGroup(Db);
            _countryGroupBuilder = new CountryGroupBuilder {Id = "a"};
        }

        readonly ICountryGroup _countryGroup;
        readonly CountryGroupBuilder _countryGroupBuilder;

        [Fact]
        public void ShouldNotReturnCountriesWhichIsCeased()
        {
            _countryGroupBuilder.Build().In(Db).DateCeased = DateTime.Today.AddDays(-1);

            var r = _countryGroup.GetMemberCountries("a");

            Assert.Empty(r);
        }

        [Fact]
        public void ShouldNotReturnCountriesWhichIsNotCommenced()
        {
            _countryGroupBuilder.Build().In(Db).DateCommenced = DateTime.Today.AddDays(1);

            var r = _countryGroup.GetMemberCountries("a");

            Assert.Empty(r);
        }

        [Fact]
        public void ShouldReturnCountriesWhichIsCommenced()
        {
            _countryGroupBuilder.Build().In(Db).DateCommenced = DateTime.Today.AddDays(-1);

            var r = _countryGroup.GetMemberCountries("a");

            Assert.Single(r);
        }

        [Fact]
        public void ShouldReturnCountriesWhichIsNotCeased()
        {
            _countryGroupBuilder.Build().In(Db).DateCeased = DateTime.Today.AddDays(1);

            var r = _countryGroup.GetMemberCountries("a");

            Assert.Single(r);
        }
    }
}