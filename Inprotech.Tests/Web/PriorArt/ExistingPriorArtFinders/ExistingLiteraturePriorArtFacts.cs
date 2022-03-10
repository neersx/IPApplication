using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.PriorArt;
using Inprotech.Web.PriorArt.ExistingPriorArtFinders;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.ExistingPriorArtFinders
{
    public class ExistingLiteraturePriorArtFacts : FactBase
    {
        ExistingLiteraturePriorArt CreateSubject()
        {
            return new ExistingLiteraturePriorArt(Db);
        }

        [Fact]
        public async Task ShouldReturnOnlyLiteratureDocuments()
        {
            var request = new SearchRequest();

            var priorart1 = new PriorArtBuilder().Build().In(Db);
            var priorart2 = new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().BuildSourceDocument().In(Db);
            new PriorArtBuilder().BuildSourceDocument().In(Db);
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count());
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }

        [Fact]
        public async Task ShouldReturnOnlyLiteratureDocumentsWithMatchingDescriptions()
        {
            var request = new SearchRequest
            {
                Description = Fixture.String()
            };

            var priorart1 = new PriorArtBuilder().Build().In(Db);
            var priorart2 = new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().Build().In(Db);
            priorart1.Description = Fixture.String(request.Description);
            priorart2.Description = Fixture.String(request.Description);
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count());
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }

        [Fact]
        public async Task ShouldReturnOnlyLiteratureDocumentsWithMatchingInventors()
        {
            var request = new SearchRequest
            {
                Inventor = Fixture.String()
            };

            var priorart1 = new PriorArtBuilder().Build().In(Db);
            var priorart2 = new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().Build().In(Db);
            priorart1.Name = Fixture.String(request.Inventor);
            priorart2.Name = Fixture.String(request.Inventor);
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count());
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }

        [Fact]
        public async Task ShouldReturnOnlyLiteratureDocumentsWithMatchingTitle()
        {
            var request = new SearchRequest
            {
                Title = Fixture.String()
            };

            var priorart1 = new PriorArtBuilder().Build().In(Db);
            var priorart2 = new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().Build().In(Db);
            priorart1.Title = Fixture.String(request.Title);
            priorart2.Title = Fixture.String(request.Title);
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count());
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }

        [Fact]
        public async Task ShouldReturnOnlyLiteratureDocumentsWithMatchingPublisher()
        {
            var request = new SearchRequest
            {
                Publisher = Fixture.String()
            };

            var priorart1 = new PriorArtBuilder().Build().In(Db);
            var priorart2 = new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().Build().In(Db);
            new PriorArtBuilder().Build().In(Db);
            priorart1.Publisher = Fixture.String(request.Publisher);
            priorart2.Publisher = Fixture.String(request.Publisher);
            var subject = CreateSubject();

            var result = subject.GetExistingPriorArt(request).ToList();

            Assert.Equal(2, result.Count());
            Assert.Contains(priorart1, result);
            Assert.Contains(priorart2, result);
        }
    }
}