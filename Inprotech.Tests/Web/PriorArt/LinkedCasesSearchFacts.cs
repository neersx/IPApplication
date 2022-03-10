using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Components.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class LinkedCasesSearchFacts : FactBase
    {
        [Fact]
        public async Task ShouldReturnNoRowsIfNoMatchingRecords()
        {
            var fixture = new LinkedCasesSearchFixture(Db);

            var result = await fixture.Subject.Search(new SearchRequest(), new CommonQueryParameters().Filters);

            Assert.Empty(result);
        }
        
        [Fact]
        public async Task ShouldReturnMatchingPriorArtIdRecords()
        {
            var fixture = new LinkedCasesSearchFixture(Db);
            var priorArtId = Fixture.Integer();
            var case1 = new CaseBuilder().Build().In(Db);
            var case2 = new CaseBuilder().Build().In(Db);
            var case3 = new CaseBuilder().Build().In(Db);
            var caseSearchResult1 = new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case1,
                CaseListPriorArtId = fixture.CaseListSearchResult1.Id
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case1,
                CaseListPriorArtId = fixture.CaseListSearchResult2.Id
            }.In(Db);
            var caseSearchResult2 = new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case2,
                FamilyPriorArtId = fixture.FamilySearchResult.Id
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case2,
                CaseListPriorArtId = fixture.CaseListSearchResult2.Id
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case2
            }.In(Db);

            var caseSearchResult3 = new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case3,
                NamePriorArtId = fixture.NameSearchResult.Id
            }.In(Db);
            
            var formattedNames = new Dictionary<int, NameFormatted> {{fixture.NameSearchResult.NameId, new NameFormatted {NameId = fixture.NameSearchResult.NameId, Name = fixture.NameSearchResult.Name.Formatted()}}};
            fixture.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formattedNames);

            var result = await fixture.Subject.Search(new SearchRequest {SourceDocumentId = priorArtId}, new CommonQueryParameters.FilterValue[0]);
            var list = result.ToArray();

            Assert.Equal(3, list.Length);
            Assert.NotNull(list.Single(_ => _.CaseKey == caseSearchResult1.CaseId && _.CaseList == "Case-List-abc, Case-List-XYZ"));
            Assert.NotNull(list.Single(_ => _.CaseKey == caseSearchResult2.CaseId && _.FamilyCode.StartsWith("NEW-FAMILY") && _.Family.StartsWith("Family Name") && _.CaseList == "Case-List-XYZ"));
            Assert.NotNull(list.Single(_ => _.CaseKey == caseSearchResult3.CaseId && _.LinkedViaNames.StartsWith(fixture.NameSearchResult.Name.Formatted())));
        }

        [Fact]
        public async Task ShouldDisplayIndirectlyLinkedCases()
        {
            var fixture = new LinkedCasesSearchFixture(Db);
            var priorArtId = Fixture.Integer();
            var case1 = new CaseBuilder {FamilyId = fixture.FamilySearchResult.FamilyId}.Build().In(Db);
            var case2 = new CaseBuilder().Build().In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case1,
                UpdateDate = Fixture.PastDate()
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case1,
                FamilyPriorArtId = fixture.FamilySearchResult.Id,
                UpdateDate = Fixture.Today()
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case1,
                CaseListPriorArtId = fixture.CaseListSearchResult2.Id
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case1,
                NamePriorArtId = fixture.NameSearchResult.Id
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case2
            }.In(Db);
            var formattedNames = new Dictionary<int, NameFormatted> {{fixture.NameSearchResult.NameId, new NameFormatted {NameId = fixture.NameSearchResult.NameId, Name = fixture.NameSearchResult.Name.Formatted()}}};
            fixture.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formattedNames);

            var result = await fixture.Subject.Search(new SearchRequest {SourceDocumentId = priorArtId}, new CommonQueryParameters.FilterValue[0]);
            var list = result.ToArray();
            Assert.Equal(2, list.Length);
            Assert.NotNull(list.Single(_ => _.CaseKey == case1.Id &&
                                            _.FamilyCode.StartsWith("NEW-FAMILY") &&
                                            _.Family.StartsWith("Family Name") &&
                                            _.CaseList == "Case-List-XYZ" &&
                                            _.LinkedViaNames.StartsWith(fixture.NameSearchResult.Name.Formatted())));
            Assert.NotNull(list.Single(_ => _.CaseKey == case2.Id && string.IsNullOrEmpty(_.Family) && string.IsNullOrEmpty(_.CaseList) && string.IsNullOrEmpty(_.LinkedViaNames)));
        }
        
        [Fact]
        public async Task ShouldReturnMatchingCaseRefFilter()
        {
            var priorArtId = Fixture.Integer();
            var case1 = new CaseBuilder().Build().In(Db);
            var case2 = new CaseBuilder().Build().In(Db);
            var case3 = new CaseBuilder().Build().In(Db);
            var caseSearchResult1 = new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case1
            }.In(Db);
            var caseSearchResult2 = new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case2
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case3
            }.In(Db);

            var fixture = new LinkedCasesSearchFixture(Db);

            var result = await fixture.Subject.Search(new SearchRequest {SourceDocumentId = priorArtId}, new []
            {
                new CommonQueryParameters.FilterValue()
                {
                    Field = "caseReference",
                    Value = $"{case1.Id},{case2.Id}"
                }
            });
            var list = result.ToArray();

            Assert.Equal(2, list.Length);
            Assert.NotNull(list.Single(_ => _.CaseKey == caseSearchResult1.CaseId));
            Assert.NotNull(list.Single(_ => _.CaseKey == caseSearchResult2.CaseId));
        }
        
        [Fact]
        public async Task ShouldReturnMatchingOfficialNumbersFilter()
        {
            var priorArtId = Fixture.Integer();
            var case1 = new CaseBuilder().Build().In(Db);
            case1.CurrentOfficialNumber = Fixture.String();
            var case2 = new CaseBuilder().Build().In(Db);
            case2.CurrentOfficialNumber = Fixture.String();
            var case3 = new CaseBuilder().Build().In(Db);
            case3.CurrentOfficialNumber = Fixture.String();
            var caseSearchResult1 = new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case1
            }.In(Db);
            var caseSearchResult2 = new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case2
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case3
            }.In(Db);

            var fixture = new LinkedCasesSearchFixture(Db);

            var result = await fixture.Subject.Search(new SearchRequest {SourceDocumentId = priorArtId}, new []
            {
                new CommonQueryParameters.FilterValue()
                {
                    Field = "officialNumber",
                    Value = $"{case1.CurrentOfficialNumber},{case2.CurrentOfficialNumber}"
                }
            });
            var list = result.ToArray();

            Assert.Equal(2, list.Length);
            Assert.NotNull(list.Single(_ => _.CaseKey == caseSearchResult1.CaseId));
            Assert.NotNull(list.Single(_ => _.CaseKey == caseSearchResult2.CaseId));
        }

        [Fact]
        public async Task ShouldReturnMatchingCaseRelationshipFilter()
        {
            var priorArtId = Fixture.Integer();
            var case1 = new CaseBuilder().Build().In(Db);
            case1.CurrentOfficialNumber = Fixture.String();
            var case2 = new CaseBuilder().Build().In(Db);
            case2.CurrentOfficialNumber = Fixture.String();
            var case3 = new CaseBuilder().Build().In(Db);
            case3.CurrentOfficialNumber = Fixture.String();
            var caseSearchResult1 = new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case1,
                IsCaseRelationship = true
            }.In(Db);
            var caseSearchResult2 = new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case2,
                IsCaseRelationship = true
            }.In(Db);
            new CaseSearchResult
            {
                Id = Fixture.Integer(),
                PriorArtId = priorArtId,
                Case = case3
            }.In(Db);

            var fixture = new LinkedCasesSearchFixture(Db);

            var result = await fixture.Subject.Search(new SearchRequest {SourceDocumentId = priorArtId}, new []
            {
                new CommonQueryParameters.FilterValue()
                {
                    Field = "relationship",
                    Value = "true"
                }
            });
            var list = result.ToArray();

            Assert.Equal(2, list.Length);
            Assert.NotNull(list.Single(_ => _.CaseKey == caseSearchResult1.CaseId));
            Assert.NotNull(list.Single(_ => _.CaseKey == caseSearchResult2.CaseId));
        }

        [Theory]
        [InlineData(DisplayNameCode.End)]
        [InlineData(DisplayNameCode.Start)]
        [InlineData(DisplayNameCode.None)]
        public void ShouldFormatNamesCorrectly(DisplayNameCode display)
        {
            var fixture = new LinkedCasesSearchFixture(Db);
            var nameType = new NameTypeBuilder {ShowNameCode = (decimal?) display}.Build().In(Db);
            var formattedName = Fixture.String("Formatted Name");
            var nameCode = Fixture.Integer().ToString();
            var result = fixture.Subject.FormatLinkedName(formattedName, nameCode, nameType);

            if (display == DisplayNameCode.End)
            {
                Assert.Equal(formattedName + $" {{{nameCode}}}" + $" {{{nameType.NameTypeCode}}}", result);
            }
            if (display == DisplayNameCode.Start)
            {
                Assert.Equal($"{{{nameCode}}} " + formattedName + $" {{{nameType.NameTypeCode}}}", result);
            }
            if (display == DisplayNameCode.None)
            {
                Assert.Equal(formattedName + $" {{{nameType.NameTypeCode}}}", result);
            }
        }

        public class LinkedCasesSearchFixture : IFixture<LinkedCaseSearch>
        {
            public LinkedCasesSearchFixture(InMemoryDbContext db)
            {
                var family = new Family(Fixture.String("NEW-FAMILY"), Fixture.String("Family Name")).In(db);
                FamilySearchResult = new FamilySearchResult {FamilyId = family.Id, PriorArtId = Fixture.Integer(), Family = family}.In(db);
                NameSearchResult = new NameSearchResult {Name = new NameBuilder(db).Build().In(db), NameType = new NameTypeBuilder().Build().In(db), PriorArtId = Fixture.Integer()}.In(db);
                var caseList1 = new CaseList(Fixture.Integer(), "Case-List-abc").In(db);
                var caseList2 = new CaseList(Fixture.Integer(), "Case-List-XYZ").In(db);
                CaseListSearchResult1 = new CaseListSearchResult {CaseListId = caseList1.Id, PriorArtId = Fixture.Integer(), CaseList = caseList1}.In(db);
                CaseListSearchResult2 = new CaseListSearchResult {CaseListId = caseList2.Id, PriorArtId = Fixture.Integer(), CaseList = caseList2}.In(db);
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                Subject = new LinkedCaseSearch(db, Substitute.For<IPreferredCultureResolver>(), DisplayFormattedName);
            }

            public LinkedCaseSearch Subject { get; }
            public IDisplayFormattedName DisplayFormattedName { get; set; }
            public FamilySearchResult FamilySearchResult { get; set; }
            public NameSearchResult NameSearchResult { get; set; }
            public CaseListSearchResult CaseListSearchResult1 { get; set; }
            public CaseListSearchResult CaseListSearchResult2 { get; set; }
        }
    }
}