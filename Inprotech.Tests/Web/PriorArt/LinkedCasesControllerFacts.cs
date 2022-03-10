using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class LinkedCasesControllerFacts : FactBase
    {
        [Fact]
        public async Task ChecksForDuplicateLinkedCase()
        {
            var f = new LinkedCasesControllerFixture(Db);
            var @case = new CaseBuilder().Build().In(Db);
            var existingCaseReference = new CaseSearchResult(@case.Id, f.PriorArt.Id, false).In(Db);
            var result = await f.Subject.CreateAssociation(new AssociateReferenceRequest {SourceDocumentId = existingCaseReference.PriorArtId, CaseKey = existingCaseReference.CaseId});
            Assert.False(result.IsSuccessful);
            Assert.True(result.CaseReferenceExists);
        }

        [Fact]
        public async Task ChecksForDuplicateLinkedCaseFamily()
        {
            var f = new LinkedCasesControllerFixture(Db);
            var @case = new CaseBuilder().Build().In(Db);
            var existingCaseReference = new CaseSearchResult(@case.Id, f.PriorArt.Id, false).In(Db);
            var existingFamilyReference = new FamilySearchResult() {FamilyId = Fixture.String("Family1"), PriorArtId = f.PriorArt.Id}.In(Db);
            var result = await f.Subject.CreateAssociation(new AssociateReferenceRequest {SourceDocumentId = existingCaseReference.PriorArtId, CaseKey = existingCaseReference.CaseId, CaseFamilyKey = existingFamilyReference.FamilyId});
            Assert.False(result.IsSuccessful);
            Assert.True(result.CaseReferenceExists);
            Assert.True(result.IsFamilyExisting);
        }

        [Fact]
        public async Task ChecksForDuplicateLinkedCaseList()
        {
            var f = new LinkedCasesControllerFixture(Db);
            var @case = new CaseBuilder().Build().In(Db);
            var existingCaseReference = new CaseSearchResult(@case.Id, f.PriorArt.Id, false).In(Db);
            var existingFamilyReference = new FamilySearchResult() {FamilyId = Fixture.String("Family1"), PriorArtId = f.PriorArt.Id}.In(Db);
            var existingCaseList = new CaseListSearchResult() {CaseListId = Fixture.Integer(), PriorArtId = f.PriorArt.Id}.In(Db);
            var result = await f.Subject.CreateAssociation(new AssociateReferenceRequest
            {
                SourceDocumentId = existingCaseReference.PriorArtId,
                CaseKey = existingCaseReference.CaseId,
                CaseFamilyKey = existingFamilyReference.FamilyId,
                CaseListKey = existingCaseList.CaseListId
            });
            Assert.False(result.IsSuccessful);
            Assert.True(result.CaseReferenceExists);
            Assert.True(result.IsFamilyExisting);
            Assert.True(result.IsCaseListExisting);
        }

        [Theory]
        [InlineData(false)]
        [InlineData(true)]
        public async Task ChecksForDuplicateNames(bool withNameType)
        {
            var f = new LinkedCasesControllerFixture(Db);
            var @case = new CaseBuilder().Build().In(Db);
            var existingCaseReference = new CaseSearchResult(@case.Id, f.PriorArt.Id, false).In(Db);
            var existingNameResult = new NameSearchResult {Name = new NameBuilder(Db).Build(), NameType = withNameType ? new NameTypeBuilder().Build().In(Db) : null, PriorArtId = f.PriorArt.Id}.In(Db);
            var result = await f.Subject.CreateAssociation(new AssociateReferenceRequest
            {
                SourceDocumentId = existingCaseReference.PriorArtId,
                CaseKey = existingCaseReference.CaseId,
                NameKey = existingNameResult.NameId
            });
            Assert.False(result.IsSuccessful);
            Assert.True(result.CaseReferenceExists);
            Assert.True(result.IsNameExisting);
        }

        [Theory]
        [InlineData(false)]
        [InlineData(true)]
        public async Task ChecksForDuplicateNamesRegardlessOfNameType(bool withMatchingNameType)
        {
            var f = new LinkedCasesControllerFixture(Db);
            var @case = new CaseBuilder().Build().In(Db);
            var existingCaseReference = new CaseSearchResult(@case.Id, f.PriorArt.Id, false).In(Db);
            var existingNameResult = new NameSearchResult {Name = new NameBuilder(Db).Build(), NameType = new NameTypeBuilder().Build().In(Db), PriorArtId = f.PriorArt.Id}.In(Db);
            var result = await f.Subject.CreateAssociation(new AssociateReferenceRequest
            {
                SourceDocumentId = existingCaseReference.PriorArtId,
                CaseKey = existingCaseReference.CaseId,
                NameKey = existingNameResult.NameId,
                NameTypeKey = withMatchingNameType ? existingNameResult.NameTypeCode : Fixture.RandomString(2)
            });
            Assert.False(result.IsSuccessful);
            Assert.True(result.CaseReferenceExists);
            Assert.True(result.IsNameExisting);
        }

        [Theory]
        [InlineData(true, false, false, false)]
        [InlineData(false, true, false, false)]
        [InlineData(false, false, false, false)]
        [InlineData(true, false, true, false)]
        [InlineData(false, true, true, false)]
        [InlineData(false, false, true, false)]
        [InlineData(true, false, false, true)]
        [InlineData(false, true, false, true)]
        [InlineData(false, false, false, true)]
        [InlineData(true, false, true, true)]
        [InlineData(false, true, true, true)]
        [InlineData(false, false, true, true)]
        public async Task SavesNewLinkedCase(bool samePriorArt, bool sameCase, bool sameFamily, bool sameCaseList)
        {
            var @case = new CaseBuilder().Build().In(Db);
            var existingCaseReference = new CaseSearchResult(@case.Id, Fixture.Integer(), false).In(Db);
            var existingFamilyReference = new FamilySearchResult {FamilyId = Fixture.String("Family1"), PriorArtId = Fixture.Integer()}.In(Db);
            var existingCaseListReference = new CaseListSearchResult {CaseListId= Fixture.Integer(), PriorArtId = Fixture.Integer()}.In(Db);
            var priorArtToSave = existingCaseReference.PriorArtId + (samePriorArt ? 0 : 1);
            var diffCase = new CaseBuilder().Build().In(Db);
            var linkedCase = sameCase ? existingCaseReference.CaseId : diffCase.Id;
            var linkedFamily = sameFamily ? existingFamilyReference.FamilyId : Fixture.String("Family2");
            var linkedCaseList = existingCaseListReference.CaseListId + (sameCaseList ? 0 : 1);
            var f = new LinkedCasesControllerFixture(Db);
            var result = await f.Subject.CreateAssociation(new AssociateReferenceRequest {SourceDocumentId = priorArtToSave, CaseKey = linkedCase, CaseFamilyKey = linkedFamily, CaseListKey = linkedCaseList});
            Assert.True(result.IsSuccessful);
            Assert.NotNull(Db.Set<CaseSearchResult>().Single(_ => _.CaseId == linkedCase && _.PriorArtId == priorArtToSave && !_.CaseFirstLinkedTo.GetValueOrDefault()));
            Assert.NotNull(Db.Set<FamilySearchResult>().Single(_ => _.FamilyId == linkedFamily && _.PriorArtId == priorArtToSave));
            Assert.NotNull(Db.Set<CaseListSearchResult>().Single(_ => _.CaseListId == linkedCaseList && _.PriorArtId == priorArtToSave));
        }
        
    }
    public class LinkedCasesControllerFixture : IFixture<LinkedCasesController>
    {
        public LinkedCasesControllerFixture(InMemoryDbContext dbContext)
        {
            PriorArt = new InprotechKaizen.Model.PriorArt.PriorArt {Id = Fixture.Integer(), IsSourceDocument = false}.In(dbContext);
            SiteConfiguration = Substitute.For<ISiteConfiguration>();
            TransactionRecordal = Substitute.For<ITransactionRecordal>();
            ComponentResolver = Substitute.For<IComponentResolver>();
            Subject = new LinkedCasesController(dbContext, SiteConfiguration, TransactionRecordal, ComponentResolver);
        }

        public InprotechKaizen.Model.PriorArt.PriorArt PriorArt { get; set; }
        public ISiteConfiguration SiteConfiguration { get; set; }
        public ITransactionRecordal TransactionRecordal { get; set; }
        public IComponentResolver ComponentResolver { get; set; }
        public LinkedCasesController Subject { get; }
    }
}
