using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using RelatedCase = InprotechKaizen.Model.Cases.RelatedCase;

namespace Inprotech.Tests.Web.Cases.Details.AssignmentRecordal
{
    public class AssignmentRecordalHelperFacts
    {
        public class AssignmentRecordalHelperFixture : IFixture<AssignmentRecordalHelper>
        {
            public AssignmentRecordalHelperFixture(InMemoryDbContext db)
            {
                AffectedCases = Substitute.For<IAffectedCases>();
                Subject = new AssignmentRecordalHelper(db, AffectedCases);
            }

            public AssignmentRecordalHelper Subject { get; set; }
            public IAffectedCases AffectedCases { get; set; }
        }
        
        public class GetAffectedCasesToBeChanged : FactBase
        {
            [Fact]
            public void ReturnsAffectedCasesWhereRowKeysMatched()
            {
                var f = new AssignmentRecordalHelperFixture(Db);
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var country = new CountryBuilder().Build().In(Db);
                const string officialNo = "111111";
                var rt = new RecordalType();
                new RecordalAffectedCase {Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1, AgentId = Fixture.Integer()}.In(Db);
                new RecordalAffectedCase {Case = mainCase, CaseId = mainCase.Id, Country = country, CountryId = country.Id, OfficialNumber = officialNo, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1, AgentId = 1}.In(Db);

                var result = f.Subject.GetAffectedCases(mainCase.Id, new[] {mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber}).ToArray();
                Assert.Equal(1, result.Length);
                Assert.Equal(rc1.Id, result[0].RelatedCaseId);
            } 

            [Fact]
            public async Task ReturnsAffectedCasesWhereSelectedRowKeysMatched()
            {
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var country = new CountryBuilder().Build().In(Db);
                const string officialNo = "111111";
                var rt = new RecordalType();
                new RecordalAffectedCase {Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1, AgentId = Fixture.Integer()}.In(Db);
                new RecordalAffectedCase {Case = mainCase, CaseId = mainCase.Id, Country = country, CountryId = country.Id, OfficialNumber = officialNo, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1, AgentId = 1}.In(Db);
                
                var f = new AssignmentRecordalHelperFixture(Db);
                var model = new DeleteAffectedCaseModel
                {
                    SelectedRowKeys = new List<string>
                    {
                        mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber,
                        mainCase.Id + "^^" + country.Id + "^" + officialNo
                    }
                };
                var result = (await f.Subject.GetAffectedCasesToBeChanged(mainCase.Id, model)).ToArray();
                Assert.Equal(2, result.Length);
            }

            [Fact]
            public async Task CallsAffectedCasesWhenFilterPresent()
            {
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var rt = new RecordalType();
                new RecordalAffectedCase {Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1, AgentId = Fixture.Integer()}.In(Db);
                
                var f = new AssignmentRecordalHelperFixture(Db);
                var model = new DeleteAffectedCaseModel
                {
                    IsAllSelected = true,
                    Filter = new AffectedCasesFilterModel()
                };
                f.AffectedCases.GetAffectedCasesData(Arg.Any<int>(), Arg.Any<CommonQueryParameters>(), Arg.Any<AffectedCasesFilterModel>()).Returns(new List<AffectedCasesData>
                {
                    new AffectedCasesData
                    {
                        CaseId = rc1.Id,
                        RowKey = mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber
                    }
                });
                var result = (await f.Subject.GetAffectedCasesToBeChanged(mainCase.Id, model)).ToArray();
                Assert.Equal(1, result.Length);
                Assert.Equal(rc1.Id, result[0].RelatedCaseId);
            }

            [Fact] 
            public async Task RemoveDeselectedRows()
            {
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var rc2 = new CaseBuilder().Build().In(Db);
                var rt = new RecordalType();
                new RecordalAffectedCase {Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1}.In(Db);
                new RecordalAffectedCase {Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc2, RelatedCaseId = rc2.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 2}.In(Db);
                
                var f = new AssignmentRecordalHelperFixture(Db);
                var model = new DeleteAffectedCaseModel
                {
                    IsAllSelected = true,
                    DeSelectedRowKeys = new List<string>
                    {
                        mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber
                    }
                };
                f.AffectedCases.GetAffectedCasesData(Arg.Any<int>(), Arg.Any<CommonQueryParameters>(), Arg.Any<AffectedCasesFilterModel>()).Returns(new List<AffectedCasesData>
                {
                    new AffectedCasesData
                    {
                        CaseId = rc1.Id,
                        RowKey = mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber
                    },
                    new AffectedCasesData
                    {
                        CaseId = rc1.Id,
                        RowKey = mainCase.Id + "^" + rc2.Id + "^" + rc2.CountryId + "^" + rc2.CurrentOfficialNumber
                    }
                });
                var result = (await f.Subject.GetAffectedCasesToBeChanged(mainCase.Id, model)).ToArray();
                Assert.Equal(1, result.Length);
                Assert.Equal(rc2.Id, result[0].RelatedCaseId);
            }
        }

        public class AddRemoveRelatedCases : FactBase
        {
            [Fact]
            public void GetAssignmentRecordalRelationshipShouldReturnValues()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var relation = new CaseRelationBuilder {RelationshipCode = KnownRelations.AssignmentRecordal}.Build().In(Db);
                var reverseRelation = new CaseRelationBuilder {RelationshipCode = KnownRelations.EarliestPriority}.Build().In(Db);
                new ValidRelationship(@case.Country, @case.PropertyType, relation, reverseRelation).In(Db);

                var f = new AssignmentRecordalHelperFixture(Db);
                f.Subject.GetAssignmentRecordalRelationship(@case, out var relationship, out var reverseRelationship);
                Assert.Equal(relation, relationship);
                Assert.Equal(reverseRelation, reverseRelationship);
            }

            [Fact]
            public void GetRelationshipShouldReturnValuesWithDefaultCountry()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var relation = new CaseRelationBuilder {RelationshipCode = KnownRelations.AssignmentRecordal}.Build().In(Db);
                var reverseRelation = new CaseRelationBuilder {RelationshipCode = KnownRelations.EarliestPriority}.Build().In(Db);
                var defaultCountry = new CountryBuilder {Id = KnownValues.DefaultCountryCode}.Build().In(Db);
                new ValidRelationship(defaultCountry, @case.PropertyType, relation, reverseRelation).In(Db);

                var f = new AssignmentRecordalHelperFixture(Db);
                f.Subject.GetAssignmentRecordalRelationship(@case, out var relationship, out var reverseRelationship);
                Assert.Equal(relation, relationship);
                Assert.Equal(reverseRelation, reverseRelationship);
            }

            [Fact]
            public void ShouldNotAddIfAlreadyExists()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var rc = new CaseBuilder().Build().In(Db);
                var relation = new CaseRelationBuilder().Build().In(Db);
                var reverseRelation = new CaseRelationBuilder().Build().In(Db);
                new RelatedCase(@case.Id, relation.Relationship) {RelatedCaseId = rc.Id}.In(Db);
                var f = new AssignmentRecordalHelperFixture(Db);
                f.Subject.AddRelatedCase(@case, rc, null, null, relation, reverseRelation, 0);
                Assert.Equal(1, Db.Set<RelatedCase>().Count());
            }

            [Fact]
            public void ShouldNotAddIfExternalCaseAlreadyExists()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var relation = new CaseRelationBuilder().Build().In(Db);
                var reverseRelation = new CaseRelationBuilder().Build().In(Db);
                new RelatedCase(@case.Id, "AU", "1111", relation).In(Db);
                var f = new AssignmentRecordalHelperFixture(Db);
                f.Subject.AddRelatedCase(@case, null, "AU", "1111", relation, reverseRelation, 0);
                Assert.Equal(1, Db.Set<RelatedCase>().Count());
            }

            [Fact]
            public void ShouldAddInternalRelatedCase()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var rc = new CaseBuilder().Build().In(Db);
                var relation = new CaseRelationBuilder().Build().In(Db);
                var reverseRelation = new CaseRelationBuilder().Build().In(Db);
                new RelatedCase(@case.Id, KnownRelations.PctDesignation) {RelatedCaseId = rc.Id, RelationshipNo = 0}.In(Db);
                var f = new AssignmentRecordalHelperFixture(Db);
                f.Subject.AddRelatedCase(@case, rc, null, null, relation, reverseRelation, 0);
                Assert.Equal(3, Db.Set<RelatedCase>().Count());
                Assert.Equal(1, Db.Set<RelatedCase>().First(_ => _.Relationship == relation.Relationship).RelationshipNo);

                var reverseRelatedCase = Db.Set<RelatedCase>().First(_ => _.Relationship == reverseRelation.Relationship);
                Assert.Equal(0, reverseRelatedCase.RelationshipNo);
                Assert.Equal(rc.Id, reverseRelatedCase.CaseId);
            }

            [Fact]
            public void ShouldRemoveInternalRelatedCases()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var rc = new CaseBuilder().Build().In(Db);
                var relation = new CaseRelationBuilder().Build().In(Db);
                var reverseRelation = new CaseRelationBuilder().Build().In(Db);
                new RelatedCase(@case.Id, relation.Relationship) {RelatedCaseId = rc.Id, RelationshipNo = 0}.In(Db);
                new RelatedCase(rc.Id, reverseRelation.Relationship) {RelatedCaseId = @case.Id, RelationshipNo = 0}.In(Db);
                var f = new AssignmentRecordalHelperFixture(Db);

                f.Subject.RemoveRelatedCase(@case, rc, null, null, relation, reverseRelation);
                Assert.False(Db.Set<RelatedCase>().Any());
            }

            [Fact]
            public void ShouldRemoveExternalRelatedCases()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var relation = new CaseRelationBuilder().Build().In(Db);
                new RelatedCase(@case.Id, "AU", "111", relation) {RelationshipNo = 0}.In(Db);
                var f = new AssignmentRecordalHelperFixture(Db);

                f.Subject.RemoveRelatedCase(@case, null, "AU", "111", relation, null);
                Assert.False(Db.Set<RelatedCase>().Any());
            }
        }

        public class AddRemoveNewOwners : FactBase
        {
            [Fact]
            public void ShouldAddNewOwners()
            {
                var @case = new CaseBuilder().Build().In(Db);
                new NameTypeBuilder {NameTypeCode = KnownNameTypes.NewOwner}.Build().In(Db);
                var n1 = new NameBuilder(Db) { StreetAddress = new AddressBuilder().Build().In(Db)}.Build().In(Db);
                var n2 = new NameBuilder(Db).Build().In(Db);
                var f = new AssignmentRecordalHelperFixture(Db);
                f.Subject.AddNewOwners(@case, n1.Id + "," + n2.Id);
                var caseNames = Db.Set<CaseName>();
                Assert.Equal(2, caseNames.Count());
                Assert.Equal(KnownNameTypes.NewOwner, caseNames.First().NameType.NameTypeCode);
                Assert.Equal(0, caseNames.First().Sequence);
                Assert.Equal(n1.StreetAddressId, caseNames.First().AddressCode);
                Assert.Equal(1, caseNames.Last().Sequence);
            }

            [Fact]
            public void ShouldRemoveNewOwners()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var nt = new NameTypeBuilder {NameTypeCode = KnownNameTypes.NewOwner}.Build().In(Db);
                var n1 = new NameBuilder(Db) { StreetAddress = new AddressBuilder().Build().In(Db)}.Build().In(Db);
                var n2 = new NameBuilder(Db).Build().In(Db);
                new CaseNameBuilder(Db) {Case = @case, Name = n1, NameType = nt}.Build().In(Db);
                new CaseNameBuilder(Db) {Case = @case, Name = n2, NameType = nt}.Build().In(Db);
                var f = new AssignmentRecordalHelperFixture(Db);
                f.Subject.RemoveNewOwners(@case, n1.Id + "," + n2.Id);
                var caseNames = Db.Set<CaseName>();
                Assert.Equal(0, caseNames.Count());
            }
        }
    }
}
