using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.PriorArt;
using Inprotech.Web.PriorArt.ExistingPriorArtFinders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.ExistingPriorArtFinders
{
    public class ExistingIpoIssuedPriorArtFacts : FactBase
    {
        ExistingIpoIssuedPriorArt CreateSubject()
        {
            return new ExistingIpoIssuedPriorArt(Db);
        }

        [Fact]
        public async Task ShouldFindExistingPriorArtMatchingCountryAndNumber()
        {
            var country = new Country(Fixture.String(), Fixture.String()).In(Db);
            var number = Fixture.String();
            var request = new SearchRequest
            {
                Country = country.Id,
                OfficialNumber = number
            };

            var priorart1 = new PriorArtBuilder
            {
                OfficialNumber = number,
                Country = country
            }.Build().In(Db);

            var priorart2 = new PriorArtBuilder
            {
                OfficialNumber = number,
                Country = country
            }.Build().In(Db);

            var priorart3 = new PriorArtBuilder
            {
                OfficialNumber = Fixture.String(),
                Country = country,
                Kind = "Unmatched-number"
            }.Build().In(Db);

            var priorart4 = new PriorArtBuilder
            {
                OfficialNumber = number,
                Country = new Country(Fixture.String(), Fixture.String()).In(Db),
                Kind = "Unmatched-country"
            }.Build().In(Db);

            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count());
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
            Assert.DoesNotContain(priorart3, result);
            Assert.DoesNotContain(priorart4, result);
        }

        [Fact]
        public async Task ShouldFindExistingPriorArtMatchingCountryNumberAndKindCode()
        {
            var country = new Country(Fixture.String(), Fixture.String()).In(Db);
            var number = Fixture.String();
            var kindCode = Fixture.String();

            var request = new SearchRequest
            {
                Country = country.Id,
                OfficialNumber = number,
                Kind = kindCode
            };

            var priorart1 = new PriorArtBuilder
            {
                OfficialNumber = number,
                Country = country,
                Kind = "unmatched-kindcode"
            }.Build().In(Db);

            var priorart2 = new PriorArtBuilder
            {
                OfficialNumber = number,
                Country = country,
                Kind = kindCode
            }.Build().In(Db);

            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(1, result.Count());
            Assert.Contains(priorart2, result);
            Assert.DoesNotContain(priorart1, result);
        }

        [Fact]
        public async Task ShouldReturnMultipleResultsWhenDoingMultiSearchRequest()
        {
            var ipoRequest1 = new IpoSearchRequest { Country = Fixture.String(), OfficialNumber = Fixture.String(), Kind = Fixture.String() };
            var ipoRequest2 = new IpoSearchRequest { Country = Fixture.String(), OfficialNumber = Fixture.String() };
            var country1 = new Country(ipoRequest1.Country, Fixture.String()).In(Db);
            var country2 = new Country(ipoRequest2.Country, Fixture.String()).In(Db);
            var request = new SearchRequest { IpoSearchType = IpoSearchType.Multiple, MultipleIpoSearch = new []{ ipoRequest1, ipoRequest2 } };
            var priorart1 = new PriorArtBuilder { OfficialNumber = ipoRequest1.OfficialNumber, Country = country1, Kind = ipoRequest1.Kind }.Build().In(Db);
            var priorart2 = new PriorArtBuilder { OfficialNumber = ipoRequest2.OfficialNumber, Country = country2 }.Build().In(Db);
            var subject = CreateSubject();
            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count);
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }
    }
}