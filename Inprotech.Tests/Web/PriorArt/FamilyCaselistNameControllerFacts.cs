using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class FamilyCaselistNameControllerFacts : FactBase
    {
        [Fact]
        public void ShouldReturnNoRowsIfNoMatchingRecords()
        {
            var fixture = new FamilyCaselistNameControllerFixture(Db);
            var result = fixture.Subject.LinkedFamilyCaseListSearch(Fixture.Integer(), CommonQueryParameters.Default);

            Assert.Equal(0, result.Pagination.Total);

            result = fixture.Subject.LinkedNamesSearch(Fixture.Integer(), CommonQueryParameters.Default);

            Assert.Equal(0, result.Result.Pagination.Total);
        }
        
        [Fact]
        public void ShouldReturnCorrectFamilyAndCaselist()
        {
            var fixture = new FamilyCaselistNameControllerFixture(Db);
            var priorArt = new InprotechKaizen.Model.PriorArt.PriorArt {Id = Fixture.Integer()}.In(Db);
            new FamilySearchResult {Id = Fixture.Integer(), PriorArtId = priorArt.Id, Family = new Family(Fixture.String(), Fixture.String())}.In(Db);
            new FamilySearchResult {Id = Fixture.Integer(), PriorArtId = priorArt.Id, Family = new Family(Fixture.String(), Fixture.String())}.In(Db);
            new FamilySearchResult {Id = Fixture.Integer(), PriorArtId = Fixture.Integer(), Family = new Family(Fixture.String(), Fixture.String())}.In(Db);
            new CaseListSearchResult {Id = Fixture.Integer(), PriorArtId = priorArt.Id, CaseList = new CaseList(Fixture.Integer(), Fixture.String())}.In(Db);
            new CaseListSearchResult {Id = Fixture.Integer(), PriorArtId = priorArt.Id, CaseList = new CaseList(Fixture.Integer(), Fixture.String())}.In(Db);
            new CaseListSearchResult {Id = Fixture.Integer(), PriorArtId = Fixture.Integer(), CaseList = new CaseList(Fixture.Integer(), Fixture.String())}.In(Db);

            var result = fixture.Subject.LinkedFamilyCaseListSearch(priorArt.Id, CommonQueryParameters.Default);

            Assert.Equal(4, result.Pagination.Total);
        }

        [Fact]
        public void ShouldReturnCorrectLinkedNames()
        {
            var fixture = new FamilyCaselistNameControllerFixture(Db);
            var priorArt = new InprotechKaizen.Model.PriorArt.PriorArt {Id = Fixture.Integer()}.In(Db);
            new NameSearchResult {Id = Fixture.Integer(), PriorArtId = priorArt.Id, Name= new NameBuilder(Db).Build()}.In(Db);
            new NameSearchResult {Id = Fixture.Integer(), PriorArtId = priorArt.Id, Name = new NameBuilder(Db).Build()}.In(Db);
            new NameSearchResult {Id = Fixture.Integer(), PriorArtId = Fixture.Integer(), Name = new NameBuilder(Db).Build()}.In(Db);

            var result = fixture.Subject.LinkedNamesSearch(priorArt.Id, CommonQueryParameters.Default);

            Assert.Equal(2, result.Result.Pagination.Total);
        }

        [Fact]
        public void ShouldReturnFamilyCaseDetails()
        {
            var fixture = new FamilyCaselistNameControllerFixture(Db);
            var priorArt = new InprotechKaizen.Model.PriorArt.PriorArt {Id = Fixture.Integer()}.In(Db);
            var familySearchResult = new FamilySearchResult {Id = Fixture.Integer(), PriorArtId = priorArt.Id, Family = new Family(Fixture.String(), Fixture.String())}.In(Db);
            var caseListResult = new CaseListSearchResult {Id = Fixture.Integer(), PriorArtId = priorArt.Id, CaseList = new CaseList(){Description = Fixture.String(), Id = Fixture.Integer()}}.In(Db);
            var case1 = new CaseBuilder
            {
                FamilyId = familySearchResult.Family.Id
            }.Build().In(Db);
            new CaseBuilder
            {
                FamilyId = familySearchResult.Family.Id
            }.Build().In(Db);
            new CaseBuilder().Build().In(Db);

            var filter = new CommonQueryParameters {SortBy = "CaseId"};

            var result = fixture.Subject.FamilyNamesCaseDetails(new FamilyCaselistNameController.LinkedFamilyOrList
            {
                Id = caseListResult.Id,
                IsFamily = false
            }, filter);

            Assert.Equal(0, result.Pagination.Total);

            result = fixture.Subject.FamilyNamesCaseDetails(new FamilyCaselistNameController.LinkedFamilyOrList
            {
                Id = familySearchResult.Id,
                IsFamily = true
            }, filter);

            Assert.Equal(2, result.Pagination.Total);
            Assert.True(result.Data.Any(v => v.CaseId == case1.Id));
        }
    }

    public class RemovingAssociations : FactBase
    {
        [Fact]
        public async Task DeletesFamilyPriorArt()
        {
            var priorArtId = Fixture.Integer();
            var familyPriorArtId = Fixture.Integer();
            CreateTestData(familyPriorArtId, priorArtId);
            var f = new FamilyCaselistNameControllerFixture(Db);
            var result = await f.Subject.RemoveFamilyFor(priorArtId, familyPriorArtId);
            Assert.True(result.IsSuccessful);
            Assert.Null(Db.Set<FamilySearchResult>().SingleOrDefault(_ => _.Id == familyPriorArtId && _.PriorArtId == priorArtId));
            Assert.Equal(2, Db.Set<FamilySearchResult>().Count());
            Assert.Equal(3, Db.Set<CaseListSearchResult>().Count());
            Assert.Equal(3, Db.Set<NameSearchResult>().Count());
        }

        [Fact]
        public async Task DeletesCaseListPriorArt()
        {
            var priorArtId = Fixture.Integer();
            var caseListPriorArtId = Fixture.Integer();
            var f = new FamilyCaselistNameControllerFixture(Db);
            CreateTestData(caseListPriorArtId, priorArtId);
            var result = await f.Subject.RemoveCaseListFor(priorArtId, caseListPriorArtId);
            Assert.True(result.IsSuccessful);
            Assert.Null(Db.Set<CaseListSearchResult>().SingleOrDefault(_ => _.Id == caseListPriorArtId && _.PriorArtId == priorArtId));
            Assert.Equal(2, Db.Set<CaseListSearchResult>().Count());
            Assert.Equal(3, Db.Set<NameSearchResult>().Count());
            Assert.Equal(3, Db.Set<FamilySearchResult>().Count());
        }

        [Fact]
        public async Task DeletesNamePriorArt()
        {
            var priorArtId = Fixture.Integer();
            var namePriorArtId = Fixture.Integer();
            var f = new FamilyCaselistNameControllerFixture(Db);
            CreateTestData(namePriorArtId, priorArtId);
            var result = await f.Subject.RemoveNameFor(priorArtId, namePriorArtId);
            Assert.True(result.IsSuccessful);
            Assert.Null(Db.Set<NameSearchResult>().SingleOrDefault(_ => _.Id == namePriorArtId && _.PriorArtId == priorArtId));
            Assert.Equal(2, Db.Set<NameSearchResult>().Count());
            Assert.Equal(3, Db.Set<CaseListSearchResult>().Count());
            Assert.Equal(3, Db.Set<FamilySearchResult>().Count());
        }

        void CreateTestData(int linkedPriorArtId, int priorArtId)
        {
            new FamilySearchResult {Id = linkedPriorArtId, PriorArtId = priorArtId, Family = new Family(Fixture.String(), Fixture.String())}.In(Db);
            new FamilySearchResult {Id = Fixture.Integer(), PriorArtId = priorArtId, Family = new Family(Fixture.String(), Fixture.String())}.In(Db);
            new FamilySearchResult {Id = linkedPriorArtId, PriorArtId = Fixture.Integer(), Family = new Family(Fixture.String(), Fixture.String())}.In(Db);
            new CaseListSearchResult {Id = linkedPriorArtId, PriorArtId = priorArtId, CaseList = new CaseList(Fixture.Integer(), Fixture.String())}.In(Db);
            new CaseListSearchResult {Id = Fixture.Integer(), PriorArtId = priorArtId, CaseList = new CaseList(Fixture.Integer(), Fixture.String())}.In(Db);
            new CaseListSearchResult {Id = linkedPriorArtId, PriorArtId = Fixture.Integer(), CaseList = new CaseList(Fixture.Integer(), Fixture.String())}.In(Db);
            new NameSearchResult {Id = Fixture.Integer(), PriorArtId = priorArtId, Name = new NameBuilder(Db).Build()}.In(Db);
            new NameSearchResult {Id = linkedPriorArtId, PriorArtId = priorArtId, Name = new NameBuilder(Db).Build()}.In(Db);
            new NameSearchResult {Id = linkedPriorArtId, PriorArtId = Fixture.Integer(), Name = new NameBuilder(Db).Build()}.In(Db);
        }
    }

    public class FamilyCaselistNameControllerFixture : IFixture<FamilyCaselistNameController>
    {
        public FamilyCaselistNameControllerFixture(IDbContext db)
        {
            Culture = Substitute.For<IPreferredCultureResolver>();
            FormattedName = Substitute.For<IDisplayFormattedName>();
            Subject = new FamilyCaselistNameController(db, Culture, FormattedName);
        }

        public IPreferredCultureResolver Culture { get; set; }
        public IDisplayFormattedName FormattedName { get; set; }
        public FamilyCaselistNameController Subject { get; set; }
    }
}
