using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.Maintenance
{
    public class RemoveLinkedCasesControllerFacts : FactBase
    {
        [Fact]
        public async Task DeletesMatchingCaseSearchResult()
        {
            var sourceId = Fixture.Integer();
            var caseId = Fixture.Integer();
            new CaseSearchResult
            {
                CaseId = caseId,
                PriorArtId = sourceId
            }.In(Db);
            new CaseSearchResult
            {
                CaseId = caseId + 1,
                PriorArtId = sourceId
            }.In(Db);
            new CaseSearchResult
            {
                CaseId = caseId,
                PriorArtId = sourceId + 1
            }.In(Db);

            var f = new RemoveLinkedCasesControllerFixture(Db, sourceId);
            Assert.Equal(3, Db.Set<CaseSearchResult>().Count());

            var result = await f.Subject.RemoveLinkedCases(new RemovePriorArtSelection { Request = new RemoveLinkedCasesRequest{ SourceDocumentId = sourceId, CaseKeys = new []{caseId} }});
            Assert.True(result.IsSuccessful);
            Assert.Equal(2, Db.Set<CaseSearchResult>().Count());
            Assert.False(Db.Set<CaseSearchResult>().Any(_ => _.CaseId == caseId && _.PriorArtId == sourceId));
        }

        [Fact]
        public async Task DeletesMultipleMatchingCaseSearchResult()
        {
            var sourceId = Fixture.Integer();
            var caseId1 = Fixture.Integer();
            var caseId2 = Fixture.Integer();
            new CaseSearchResult
            {
                CaseId = caseId1,
                PriorArtId = sourceId
            }.In(Db);
            new CaseSearchResult
            {
                CaseId = caseId1 + 1,
                PriorArtId = sourceId
            }.In(Db);
            new CaseSearchResult
            {
                CaseId = caseId1,
                PriorArtId = sourceId + 1
            }.In(Db);
            new CaseSearchResult
            {
                CaseId = caseId2,
                PriorArtId = sourceId
            }.In(Db);
            new CaseSearchResult
            {
                CaseId = caseId2 + 1,
                PriorArtId = sourceId
            }.In(Db);
            new CaseSearchResult
            {
                CaseId = caseId2,
                PriorArtId = sourceId + 1
            }.In(Db);

            var f = new RemoveLinkedCasesControllerFixture(Db, sourceId);
            Assert.Equal(6, Db.Set<CaseSearchResult>().Count());

            var result = await f.Subject.RemoveLinkedCases(new RemovePriorArtSelection {Request = new RemoveLinkedCasesRequest{ SourceDocumentId = sourceId, CaseKeys = new []{caseId1, caseId2} }});
            Assert.True(result.IsSuccessful);
            Assert.Equal(4, Db.Set<CaseSearchResult>().Count());
            Assert.False(Db.Set<CaseSearchResult>().Any(_ => _.CaseId == caseId1 && _.PriorArtId == sourceId));
            Assert.False(Db.Set<CaseSearchResult>().Any(_ => _.CaseId == caseId2 && _.PriorArtId == sourceId));
        }
    }

    public class RemoveLinkedCasesControllerFixture : IFixture<RemoveLinkedCasesController>
    {
        public RemoveLinkedCasesControllerFixture(InMemoryDbContext db, int sourceId)
        {
            LinkedCaseSearch = Substitute.For<ILinkedCaseSearch>();
            var linkedCases = db.Set<CaseSearchResult>().Select(caseSearchResult => new LinkedSearchModel {CaseSearchResult = caseSearchResult}).AsQueryable();
            LinkedCaseSearch.Citations(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(linkedCases);
            Subject = new RemoveLinkedCasesController(db, LinkedCaseSearch);
        }

        public ILinkedCaseSearch LinkedCaseSearch { get; set; }
        public RemoveLinkedCasesController Subject { get; }
    }
}
