using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Components.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class AffectedCasesFacts
    {
        public class AffectedCasesFixture : IFixture<AffectedCases>
        {
            public AffectedCasesFixture(InMemoryDbContext db)
            {
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                StaticTranslator = Substitute.For<IStaticTranslator>();
                CommonQueryService = Substitute.For<ICommonQueryService>();
                Subject = new AffectedCases(db, DisplayFormattedName, StaticTranslator, PreferredCultureResolver, CommonQueryService);
            }
            public AffectedCases Subject { get; }
            public IDisplayFormattedName DisplayFormattedName { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public IStaticTranslator StaticTranslator { get; }
            public ICommonQueryService CommonQueryService { get; }
        }

        public class GetAffectedCasesColumns : FactBase
        {
            [Fact]
            public async Task ShouldReturnAffectedCasesColumns()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var type1 = new RecordalType { Id = 1, RecordalTypeName = "Change of Owner" }.In(Db);
                var type2 = new RecordalType { Id = 2, RecordalTypeName = "Change of Address" }.In(Db);
                new RecordalStep { CaseId = @case.Id, Id = 1, TypeId = type1.Id, RecordalType = type1, StepId = 2 }.In(Db);
                new RecordalStep { CaseId = @case.Id, Id = 2, TypeId = type2.Id, RecordalType = type2, StepId = 1 }.In(Db);

                var f = new AffectedCasesFixture(Db);
                f.StaticTranslator.TranslateWithDefault("caseview.affectedCases.columns.status", Arg.Any<string[]>()).Returns("Status");

                var cols = (await f.Subject.GetAffectedCasesColumns(@case.Id)).ToArray();

                Assert.Equal(11, cols.Length);
                Assert.Equal("step1", cols[0].Id);
                Assert.Equal("Change of Address (1)", cols[0].Title);
                Assert.Equal("status1", cols[1].Id);
                Assert.Equal("Status (1)", cols[1].Title);
                Assert.Equal("step2", cols[2].Id);
                Assert.Equal("Change of Owner (2)", cols[2].Title);
                Assert.Equal("status2", cols[3].Id);
                Assert.Equal("Status (2)", cols[3].Title);
                Assert.Equal("caseReference", cols[4].Id);
                Assert.Equal("country", cols[5].Id);
                Assert.Equal("officialNo", cols[6].Id);
                Assert.Equal("owner", cols[7].Id);
                Assert.Equal("agent", cols[8].Id);
                Assert.Equal("propertyType", cols[9].Id);
                Assert.Equal("caseStatus", cols[10].Id);
            }
        }

        public class GetAffectedCasesData : FactBase
        {
            [Fact]
            public async Task ShouldReturnAffectedCasesOnDefaultSort()
            {
                var f = new AffectedCasesFixture(Db);
                var data = SetupData(f);
                f.CommonQueryService.Filter(Arg.Any<IEnumerable<AffectedCasesData>>(), Arg.Any<CommonQueryParameters>())
                 .Returns(x => x[0]);

                var result = await f.Subject.GetAffectedCases(data.@case.Id, new CommonQueryParameters());

                Assert.Equal(2, result.TotalRows);
                var row1 = result.Rows[0];
                var row2 = result.Rows[1];
                var caseRef = row1["caseReference"];
                Assert.Equal("abc", caseRef.value);
                Assert.Equal(data.relatedCase2.Id, caseRef.link["caseId"]);
                Assert.Equal("Agent 1 {A1}", row2["agent"].value);
                Assert.Equal("{O1} Owner 1; {O2} Owner 2", row1["owner"]);
                Assert.True((bool)row1["step1"]);
                Assert.Equal("Not yet filed", row1["status1"]);
                Assert.True((bool)row2["step1"]);
                Assert.True((bool)row2["step2"]);
                Assert.Equal("Not yet filed", row2["status1"]);
                Assert.Equal("Recorded", row2["status2"]);
                Assert.Equal(data.relatedCase2.Country.Name, row1["country"]);
            }

            [Fact]
            public async Task ShouldSortBasedOnSortDir()
            {
                var f = new AffectedCasesFixture(Db);
                var data = SetupData(f);

                f.CommonQueryService.Filter(Arg.Any<IEnumerable<AffectedCasesData>>(), Arg.Any<CommonQueryParameters>())
                 .Returns(x => x[0]);
                var result = await f.Subject.GetAffectedCases(data.@case.Id, new CommonQueryParameters { SortBy = "caseReference.value", SortDir = "desc" });

                Assert.Equal(2, result.TotalRows);
                var row1 = result.Rows[0];
                var caseRef = row1["caseReference"];
                Assert.Equal("def", caseRef.value);
                Assert.Equal(data.relatedCase1.Id, caseRef.link["caseId"]);
                Assert.Equal(data.relatedCase1.Country.Name, row1["country"]);
                Assert.NotEqual(data.relatedCase1.CurrentOfficialNumber, row1["officialNo"].value);
            }

            [Fact]
            public async Task ShouldGetResultBasedOnFilters()
            {
                var f = new AffectedCasesFixture(Db);
                var data = SetupData(f);
                var filter = new AffectedCasesFilterModel { OwnerId = data.owner2.Id, StepNo = 1, RecordalTypeNo = 1 };
                f.CommonQueryService.Filter(Arg.Any<IEnumerable<AffectedCasesData>>(), Arg.Any<CommonQueryParameters>())
                 .Returns(x => x[0]);
                var result = await f.Subject.GetAffectedCases(data.@case.Id, new CommonQueryParameters { SortBy = "caseReference.value", SortDir = "desc" }, filter);

                Assert.Equal(1, result.TotalRows);
                var row1 = result.Rows[0];
                var caseRef = row1["caseReference"];
                Assert.Equal("abc", caseRef.value);
                Assert.Equal(data.relatedCase2.Id, caseRef.link["caseId"]);
                Assert.Equal(data.relatedCase2.Country.Name, row1["country"]);
            }

            [Fact]
            public async Task ShouldHandleMultipleSameSteps()
            {
                var f = new AffectedCasesFixture(Db);
                var data = SetupData(f);
                var step = new RecordalStep { CaseId = data.@case.Id, Id = 3, TypeId = data.type1.Id, RecordalType = data.type1, StepId = 3 }.In(Db);
                new RecordalAffectedCase { CaseId = data.@case.Id, Case = data.@case, RelatedCaseId = data.relatedCase1.Id, RelatedCase = data.relatedCase1, RecordalTypeNo = data.type1.Id, RecordalType = data.type1, SequenceNo = 4, Status = "Recorded", RecordalStepSeq = step.Id }.In(Db);
                var filter = new AffectedCasesFilterModel();
                f.CommonQueryService.Filter(Arg.Any<IEnumerable<AffectedCasesData>>(), Arg.Any<CommonQueryParameters>())
                 .Returns(x => x[0]);
                var result = await f.Subject.GetAffectedCases(data.@case.Id, new CommonQueryParameters { SortBy = "caseReference.value", SortDir = "desc" }, filter);

                Assert.Equal(2, result.TotalRows);
                var row1 = result.Rows[0];
                Assert.True(row1["step1"]);
                Assert.True(row1["step3"]);
                Assert.Equal("Recorded", row1["status3"]);
            }

            [Fact]
            public void ReturnCaseIrnAndNameType()
            {
                var f = new AffectedCasesFixture(Db);
                var data = SetupData(f);

                var result = f.Subject.GetCaseRefAndNameType(data.@case.Id);
                Assert.Equal(result.caseRef, data.@case.Irn);
            }

            dynamic SetupData(AffectedCasesFixture f)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var relatedCase1 = new CaseBuilder { Irn = "def" }.Build().In(Db);
                var relatedCase2 = new CaseBuilder { Irn = "abc" }.Build().In(Db);
                var type1 = new RecordalType { Id = 1, RecordalTypeName = "Change of Owner" }.In(Db);
                var type2 = new RecordalType { Id = 2, RecordalTypeName = "Change of Address" }.In(Db);
                var step1 = new RecordalStep { CaseId = @case.Id, Id = 1, TypeId = type1.Id, RecordalType = type1, StepId = 1 }.In(Db);
                var step2 = new RecordalStep { CaseId = @case.Id, Id = 2, TypeId = type2.Id, RecordalType = type2, StepId = 2 }.In(Db);
                var country = new CountryBuilder { Id = "AU" }.Build().In(Db);
                new RecordalAffectedCase { CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase1.Id, RelatedCase = relatedCase1, RecordalTypeNo = type1.Id, RecordalType = type1, SequenceNo = 1, Status = "Not yet filed", RecordalStepSeq = step1.Id }.In(Db);
                new RecordalAffectedCase { CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase1.Id, RelatedCase = relatedCase1, RecordalTypeNo = type2.Id, RecordalType = type2, SequenceNo = 2, Status = "Recorded", RecordalStepSeq = step2.Id }.In(Db);
                new RecordalAffectedCase { CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase2.Id, RelatedCase = relatedCase2, RecordalTypeNo = type1.Id, RecordalType = type1, SequenceNo = 3, Status = "Not yet filed", RecordalStepSeq = step1.Id }.In(Db);
                var agent1 = new NameBuilder(Db).Build().In(Db);
                var owner1 = new NameBuilder(Db).Build().In(Db);
                var owner2 = new NameBuilder(Db).Build().In(Db);
                new CaseNameBuilder(Db) { Name = agent1, NameType = new NameTypeBuilder { NameTypeCode = KnownNameTypes.Agent, ShowNameCode = 2 }.Build(), Case = relatedCase1 }.Build().In(Db);
                new CaseNameBuilder(Db) { Name = owner1, NameType = new NameTypeBuilder { NameTypeCode = KnownNameTypes.Owner, ShowNameCode = 1 }.Build(), Case = relatedCase2 }.Build().In(Db);
                new CaseNameBuilder(Db) { Name = owner2, NameType = new NameTypeBuilder { NameTypeCode = KnownNameTypes.Owner, ShowNameCode = 1 }.Build(), Case = relatedCase2 }.Build().In(Db);
                var nameType = new NameTypeBuilder { NameTypeCode = KnownNameTypes.Agent, ShowNameCode = 1}.Build().In(Db);

                var formattedNames = new Dictionary<int, NameFormatted>
                {
                    {agent1.Id, new NameFormatted {Name = "Agent 1", NameCode = "A1"}},
                    {owner1.Id, new NameFormatted {Name = "Owner 1", NameCode = "O1"}},
                    {owner2.Id, new NameFormatted {Name = "Owner 2", NameCode = "O2"}}
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formattedNames);

                return new
                {
                    @case,
                    relatedCase2,
                    relatedCase1,
                    owner1,
                    owner2,
                    type1,
                    country,
                    nameType
                };
            }
        }
    }
}
