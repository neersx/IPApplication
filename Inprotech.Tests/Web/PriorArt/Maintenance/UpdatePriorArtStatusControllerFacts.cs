using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.PriorArt;
using Inprotech.Web.PriorArt.Maintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.Maintenance
{
    public class UpdatePriorArtStatusControllerFact
    {
        public class UpdatePriorArtStatus : FactBase
        {
            [Fact]
            public async Task ThrowNullExceptionWhenNoCaseIdsArePassedIn()
            {
                var fix = new UpdatePriorArtStatusControllerFixture(Db);
                var args = new UpdatePriorArtStatusRequest
                {
                    CaseKeys = null,
                    SourceDocumentId = Fixture.Integer(),
                    Status = Fixture.Integer()
                };
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await fix.Subject.UpdatePriorArtStatus(new UpdatePriorArtStatusSelection { Request = args}));
            }

            [Fact]
            public async Task ShouldUpdateStatusForCasesInTheList()
            {
                var caseSearchResult1 = new CaseSearchResult
                {
                    CaseId = Fixture.Integer(),
                    StatusId = Fixture.Integer(),
                    PriorArtId = Fixture.Integer(),
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                var caseSearchResult2 = new CaseSearchResult
                {
                    CaseId = Fixture.Integer(),
                    StatusId = Fixture.Integer(),
                    PriorArtId = caseSearchResult1.PriorArtId,
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                new CaseSearchResult
                {
                    CaseId = Fixture.Integer(),
                    StatusId = Fixture.Integer(),
                    PriorArtId = Fixture.Integer(),
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                new CaseSearchResult
                {
                    CaseId = Fixture.Integer(),
                    StatusId = Fixture.Integer(),
                    PriorArtId = Fixture.Integer(),
                    UpdateDate = Fixture.PastDate()
                }.In(Db);
                var fix = new UpdatePriorArtStatusControllerFixture(Db);
                var args = new UpdatePriorArtStatusRequest
                {
                    CaseKeys = new[] {caseSearchResult1.CaseId, caseSearchResult2.CaseId},
                    SourceDocumentId = caseSearchResult1.PriorArtId,
                    Status = Fixture.Integer()
                };
                await fix.Subject.UpdatePriorArtStatus(new UpdatePriorArtStatusSelection { Request = args });

                Assert.Equal(2, Db.Set<CaseSearchResult>().Count(v => v.StatusId == args.Status && v.PriorArtId == args.SourceDocumentId && v.UpdateDate == Fixture.Today()));
            }
        }
    }

    public class UpdatePriorArtStatusControllerFixture : IFixture<UpdatePriorArtStatusController>
    {
        public UpdatePriorArtStatusControllerFixture(InMemoryDbContext db)
        {
            LinkedCaseSearch = Substitute.For<ILinkedCaseSearch>();
            var linkedCases = db.Set<CaseSearchResult>().Select(caseSearchResult => new LinkedSearchModel {CaseSearchResult = caseSearchResult}).AsQueryable();
            LinkedCaseSearch.Citations(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(linkedCases);
            Subject = new UpdatePriorArtStatusController(db, Fixture.Today, LinkedCaseSearch);
        }

        public ILinkedCaseSearch LinkedCaseSearch { get; set; }
        public UpdatePriorArtStatusController Subject { get; }
    }
}
