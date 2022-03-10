using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.PriorArt;
using Inprotech.Web.PriorArt;
using Inprotech.Web.PriorArt.ExistingPriorArtFinders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class ExistingPriorArtFinderFacts : FactBase
    {
        readonly IExistingPriorArtMatchBuilder _builder = Substitute.For<IExistingPriorArtMatchBuilder>();
        readonly IIndex<int, IExistingPriorArtFinder> _finder = Substitute.For<IIndex<int, IExistingPriorArtFinder>>();
        ExistingPriorArtFinder CreateSubject()
        {
            return new ExistingPriorArtFinder(Db, _builder, _finder);
        }

        [Fact]
        public async Task ShouldMapMatchedRecordsUsingMatchBuilder()
        {
            var country = new Country(Fixture.String(), Fixture.String()).In(Db);
            var number = Fixture.String();
            var request = new SearchRequest
            {
                Country = country.Id,
                OfficialNumber = number,
                SourceType = 1
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

            _finder[1].GetExistingPriorArt(request).Returns(new[]
            {
                priorart1,
                priorart2
            }.AsQueryable());

            var options = new SearchResultOptions();
            var subject = CreateSubject();

            await subject.Find(request, options);

            _builder.Received(1).Build(priorart1, null, false, options);
            _builder.Received(1).Build(priorart2, null, false, options);
        }
    }
}