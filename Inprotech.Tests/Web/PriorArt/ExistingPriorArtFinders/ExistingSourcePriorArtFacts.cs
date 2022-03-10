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
    public class ExistingSourcePriorArtFacts : FactBase
    {
        ExistingSourcePriorArt CreateSubject()
        {
            return new ExistingSourcePriorArt(Db);
        }

        [Fact]
        public async Task ShouldReturnOnlySourceDocuments()
        {
            var country = new Country(Fixture.String(), Fixture.String()).In(Db);
            var number = Fixture.String();
            var request = new SearchRequest();

            var priorart1 = new PriorArtBuilder
            {
                OfficialNumber = number,
                Country = country
            }.BuildSourceDocument().In(Db);
            new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().Build().In(Db);
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(1, result.Count);
            Assert.Contains(priorart1, result);
        }

        [Fact]
        public async Task ShouldReturnOnlySourceDocumentsMatchingComments()
        {
            var request = new SearchRequest
            {
                Comments = Fixture.String()
            };

            var priorart1 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            var priorart2 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            new PriorArtBuilder().BuildSourceDocument().In(Db);
            priorart1.Comments = Fixture.String(request.Comments);
            priorart2.Comments = Fixture.String(request.Comments);
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count);
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }

        [Fact]
        public async Task ShouldReturnOnlySourceDocumentsMatchingCountryId()
        {
            var country = new Country(Fixture.String(), Fixture.String()).In(Db);
            var request = new SearchRequest
            {
                Country = country.Id
            };

            var priorart1 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            var priorart2 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            new PriorArtBuilder().BuildSourceDocument().In(Db);
            priorart1.IssuingCountryId = country.Id;
            priorart2.IssuingCountryId = country.Id;
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count);
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }

        [Fact]
        public async Task ShouldReturnOnlySourceDocumentsMatchingDescription()
        {
            var request = new SearchRequest
            {
                Description = Fixture.String()
            };

            var priorart1 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            var priorart2 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            new PriorArtBuilder().BuildSourceDocument().In(Db);
            priorart1.Description = Fixture.String(request.Description);
            priorart2.Description = Fixture.String(request.Description);
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count);
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }

        [Fact]
        public async Task ShouldReturnOnlySourceDocumentsMatchingPublication()
        {
            var request = new SearchRequest
            {
                Publication = Fixture.String()
            };

            var priorart1 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            var priorart2 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            new PriorArtBuilder().BuildSourceDocument().In(Db);
            priorart1.Publication = Fixture.String(request.Publication);
            priorart2.Publication = Fixture.String(request.Publication);
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count);
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }

        [Fact]
        public async Task ShouldReturnOnlySourceDocumentsMatchingSource()
        {
            var request = new SearchRequest
            {
                SourceId = Fixture.Integer()
            };

            var priorart1 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            var priorart2 = new PriorArtBuilder().BuildSourceDocument().In(Db);
            new PriorArtBuilder().BuildSourceDocument().In(Db);
            priorart1.SourceTypeId = request.SourceId;
            priorart2.SourceTypeId = request.SourceId;
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count);
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }
    }
}