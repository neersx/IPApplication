using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.Maintenance
{
    public class UpdateCaseFirstLinkedFacts
    {
        public class UpdateFirstLinked : FactBase
        {
            [Fact]
            public async Task SetsMatchingCaseSearchResultToFirstLinked()
            {
                var sourceId = Fixture.Integer();
                var caseId = Fixture.Integer();
                new CaseSearchResult
                {
                    CaseId = caseId,
                    PriorArtId = sourceId,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                new CaseSearchResult
                {
                    CaseId = caseId + 1,
                    PriorArtId = sourceId,
                    CaseFirstLinkedTo = true,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                new CaseSearchResult
                {
                    CaseId = caseId,
                    PriorArtId = sourceId + 1,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);

                var f = new UpdateCaseFirstLinkedFixture(Db);
                Assert.Equal(3, Db.Set<CaseSearchResult>().Count());
                await f.Subject.UpdateFirstLinkedCases(new UpdateCasesFirstLinkedViewRequest {SourceDocumentId = sourceId, CaseKeys = new[] {caseId}});
                Assert.NotNull(Db.Set<CaseSearchResult>().Single(_ => _.CaseId == caseId && _.PriorArtId == sourceId && _.CaseFirstLinkedTo.GetValueOrDefault() && _.UpdateDate == Fixture.Today()));
                Assert.NotNull(Db.Set<CaseSearchResult>().Single(_ => _.CaseId == caseId + 1 && _.PriorArtId == sourceId && !_.CaseFirstLinkedTo.GetValueOrDefault() && _.UpdateDate == Fixture.Today()));
                Assert.NotNull(Db.Set<CaseSearchResult>().Single(_ => _.CaseId == caseId && _.PriorArtId == sourceId + 1 && !_.CaseFirstLinkedTo.GetValueOrDefault() && _.UpdateDate == Fixture.PastDate()));
            }
            [Fact]
            public async Task LeavesCurrentFirstLinkedCasesUnmodified()
            {
                var sourceId = Fixture.Integer();
                var caseId = Fixture.Integer();
                new CaseSearchResult
                {
                    CaseId = caseId,
                    PriorArtId = sourceId,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                new CaseSearchResult
                {
                    CaseId = caseId + 1,
                    PriorArtId = sourceId,
                    CaseFirstLinkedTo = true,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                new CaseSearchResult
                {
                    CaseId = caseId,
                    PriorArtId = sourceId + 1,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);

                var f = new UpdateCaseFirstLinkedFixture(Db);
                Assert.Equal(3, Db.Set<CaseSearchResult>().Count());
                await f.Subject.UpdateFirstLinkedCases(new UpdateCasesFirstLinkedViewRequest {SourceDocumentId = sourceId, CaseKeys = new[] {caseId}, KeepCurrent = true});
                Assert.NotNull(Db.Set<CaseSearchResult>().Single(_ => _.CaseId == caseId && _.PriorArtId == sourceId && _.CaseFirstLinkedTo.GetValueOrDefault() && _.UpdateDate == Fixture.Today()));
                Assert.NotNull(Db.Set<CaseSearchResult>().Single(_ => _.CaseId == caseId + 1 && _.PriorArtId == sourceId && _.CaseFirstLinkedTo.GetValueOrDefault() && _.UpdateDate == Fixture.PastDate()));
                Assert.NotNull(Db.Set<CaseSearchResult>().Single(_ => _.CaseId == caseId && _.PriorArtId == sourceId + 1 && !_.CaseFirstLinkedTo.GetValueOrDefault() && _.UpdateDate == Fixture.PastDate()));
            }
            [Fact]
            public async Task ShouldNotAllowMultipleCaseSearchResultsToFirstLinked()
            {
                var sourceId = Fixture.Integer();
                var caseId = Fixture.Integer();
                new CaseSearchResult
                {
                    CaseId = caseId,
                    PriorArtId = sourceId,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                new CaseSearchResult
                {
                    CaseId = caseId + 1,
                    PriorArtId = sourceId,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                new CaseSearchResult
                {
                    CaseId = caseId,
                    PriorArtId = sourceId + 1,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);

                var f = new UpdateCaseFirstLinkedFixture(Db);
                Assert.Equal(3, Db.Set<CaseSearchResult>().Count());
                await Assert.ThrowsAsync<HttpException>(async () => await f.Subject.UpdateFirstLinkedCases(new UpdateCasesFirstLinkedViewRequest {SourceDocumentId = sourceId, CaseKeys = new[] {caseId, caseId + 1}}));
                await Db.DidNotReceive().SaveChangesAsync();
            }
        }
    }
    public class UpdateCaseFirstLinkedFixture : IFixture<UpdateCaseFirstLinkedController>
    {
        public UpdateCaseFirstLinkedFixture(InMemoryDbContext db)
        {
            Subject = new UpdateCaseFirstLinkedController(db, Fixture.Today);
        }
        public UpdateCaseFirstLinkedController Subject { get; }
    }
}