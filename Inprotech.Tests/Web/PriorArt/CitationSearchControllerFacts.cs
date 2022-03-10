using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Innography;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.PriorArt;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class CitationSearchControllerFacts
    {
        public class SearchMethod : FactBase
        {
            [Fact]
            public async Task ReturnsCitedPriorArt()
            {
                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);
                var priorArt = new PriorArtBuilder().Build().In(Db);
                source.CitedPriorArt.Add(priorArt);
                await Db.SaveChangesAsync();

                var f = new CitationSearchControllerFixture(Db);
                var result = await f.Subject.Search(new SearchRequest { SourceDocumentId = source.Id, IsSourceDocument = true});
                Assert.NotNull(result);
                Assert.Equal(1, result.Data.Count());
                Assert.True(result.Data.Any(_ => _.Id == priorArt.Id.ToString()));
            }

            [Fact]
            public async Task ReturnsCitedPriorArtPaged()
            {
                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);
                source.CitedPriorArt.Add(new PriorArtBuilder().Build().In(Db));
                source.CitedPriorArt.Add(new PriorArtBuilder().Build().In(Db));
                source.CitedPriorArt.Add(new PriorArtBuilder().Build().In(Db));
                source.CitedPriorArt.Add(new PriorArtBuilder().Build().In(Db));
                source.CitedPriorArt.Add(new PriorArtBuilder().Build().In(Db));
                source.CitedPriorArt.Add(new PriorArtBuilder().Build().In(Db));
                await Db.SaveChangesAsync();

                var f = new CitationSearchControllerFixture(Db);
                var result = await f.Subject.Search(new SearchRequest {SourceDocumentId = source.Id, IsSourceDocument = true}, new CommonQueryParameters().Extend(new CommonQueryParameters {Take = 5}));
                Assert.NotNull(result);
                Assert.Equal(5, result.Data.Count());
                Assert.Equal(6, result.Pagination.Total);
            }
            [Fact]
            public async Task ReturnsSourceDocuments()
            {
                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);
                var priorArt = new PriorArtBuilder().Build().In(Db);
                priorArt.SourceDocuments.Add(source);
                await Db.SaveChangesAsync();

                var f = new CitationSearchControllerFixture(Db);
                var result = await f.Subject.Search(new SearchRequest { SourceDocumentId = priorArt.Id, IsSourceDocument = false});
                Assert.NotNull(result);
                Assert.Equal(1, result.Data.Count());
                Assert.True(result.Data.Any(_ => _.Id == source.Id.ToString()));
            }

            [Fact]
            public async Task ReturnsSourceDocumentsPaged()
            {
                var priorArt = new PriorArtBuilder().Build().In(Db);
                priorArt.SourceDocuments.Add(new PriorArtBuilder().BuildSourceDocument().In(Db));
                priorArt.SourceDocuments.Add(new PriorArtBuilder().BuildSourceDocument().In(Db));
                priorArt.SourceDocuments.Add(new PriorArtBuilder().BuildSourceDocument().In(Db));
                priorArt.SourceDocuments.Add(new PriorArtBuilder().BuildSourceDocument().In(Db));
                priorArt.SourceDocuments.Add(new PriorArtBuilder().BuildSourceDocument().In(Db));
                priorArt.SourceDocuments.Add(new PriorArtBuilder().BuildSourceDocument().In(Db));
                await Db.SaveChangesAsync();

                var f = new CitationSearchControllerFixture(Db);
                var result = await f.Subject.Search(new SearchRequest {SourceDocumentId = priorArt.Id, IsSourceDocument = false}, new CommonQueryParameters().Extend(new CommonQueryParameters {Take = 5}));
                Assert.NotNull(result);
                Assert.Equal(5, result.Data.Count());
                Assert.Equal(6, result.Pagination.Total);
            }
        }
    }

    public class CitationSearchControllerFixture : IFixture<CitationSearchController>
    {
        public CitationSearchControllerFixture(InMemoryDbContext db)
        {
            PatentScoutUrlFormatter = Substitute.For<IPatentScoutUrlFormatter>();
            Subject = new CitationSearchController(db, PatentScoutUrlFormatter);
        }

        public IPatentScoutUrlFormatter PatentScoutUrlFormatter { get; set; }
        public CitationSearchController Subject { get; }
    }
}