using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration.SiteControl;
using NSubstitute;
using Xunit;
using RelatedCase = InprotechKaizen.Model.Cases.RelatedCase;

namespace Inprotech.Tests.Web.Cases.Details.AssignmentRecordal
{
    public class AffectedCasesMaintenanceFacts
    {
        public class AffectedCasesMaintenanceFixture : IFixture<AffectedCasesMaintenance>
        {
            public AffectedCasesMaintenanceFixture(InMemoryDbContext db)
            {
                TransactionRecordal = Substitute.For<ITransactionRecordal>();
                SiteConfiguration = Substitute.For<ISiteConfiguration>();
                ComponentResolver = Substitute.For<IComponentResolver>();
                Helper = Substitute.For<IAssignmentRecordalHelper>();
                Subject = new AffectedCasesMaintenance(db, Helper, TransactionRecordal, SiteConfiguration, ComponentResolver);
            }

            public IAssignmentRecordalHelper Helper { get; set; }
            public ITransactionRecordal TransactionRecordal { get; set; }
            public ISiteConfiguration SiteConfiguration { get; set; }
            public IComponentResolver ComponentResolver { get; set; }

            public AffectedCasesMaintenance Subject { get; set; }
        }

        public class DeleteAffectedCases : FactBase
        {
            dynamic SetupData(bool isAllNotYetFiled)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var relatedCase1 = new CaseBuilder {Irn = "def"}.Build().In(Db);
                var relatedCase2 = new CaseBuilder {Irn = "abc"}.Build().In(Db);
                var type1 = new RecordalType {Id = 1, RecordalTypeName = "Change of Owner"}.In(Db);
                var type2 = new RecordalType {Id = 2, RecordalTypeName = "Change of Address"}.In(Db);
                var step1 = new RecordalStep {CaseId = @case.Id, Id = 1, TypeId = type1.Id, RecordalType = type1, StepId = 1}.In(Db);
                var step2 = new RecordalStep {CaseId = @case.Id, Id = 2, TypeId = type2.Id, RecordalType = type2, StepId = 2}.In(Db);
                var recordalAffectedCase1 = new RecordalAffectedCase {CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase1.Id, RelatedCase = relatedCase1, RecordalTypeNo = type1.Id, RecordalType = type1, SequenceNo = 1, Status = isAllNotYetFiled ? AffectedCaseStatus.NotYetFiled : AffectedCaseStatus.Recorded, RecordalStepSeq = step1.Id}.In(Db);
                var recordalAffectedCase2 = new RecordalAffectedCase {CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase1.Id, RelatedCase = relatedCase1, RecordalTypeNo = type2.Id, RecordalType = type2, SequenceNo = 2, Status = AffectedCaseStatus.Filed, RecordalStepSeq = step2.Id}.In(Db);
                var recordalAffectedCase3 = new RecordalAffectedCase {CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase2.Id, RelatedCase = relatedCase2, RecordalTypeNo = type1.Id, RecordalType = type1, SequenceNo = 3, Status = AffectedCaseStatus.NotYetFiled, RecordalStepSeq = step1.Id}.In(Db);

                return new
                {
                    @case,
                    relatedCase1,
                    relatedCase2,
                    recordalAffectedCase1,
                    recordalAffectedCase2,
                    recordalAffectedCase3
                };
            }

            [Fact]
            public async Task ShouldDeleteAllAffectedCases()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var data = SetupData(true);

                var relatedCase1 = (Case) data.relatedCase1;
                var relatedCase2 = (Case) data.relatedCase2;
                var rowKeys = new List<string>
                {
                    data.@case.Id + "^" + relatedCase1.Id + "^" + relatedCase1.CountryId + "^" + relatedCase1.CurrentOfficialNumber,
                    data.@case.Id + "^" + relatedCase2.Id + "^" + relatedCase2.CountryId + "^" + relatedCase2.CurrentOfficialNumber
                };

                var deleteAffectedCaseModel = new DeleteAffectedCaseModel
                {
                    SelectedRowKeys = rowKeys,
                    IsAllSelected = false
                };
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);
                var result = await f.Subject.DeleteAffectedCases(data.@case.Id, deleteAffectedCaseModel);
                Assert.Equal("success", result.Result);
                Assert.Equal(0, result.CannotDeleteCaselistIds.Count);
            }

            [Fact]
            public async Task ShouldDeleteAllIfIsAllSelectedIsTrue()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var data = SetupData(true);
                var deleteAffectedCaseModel = new DeleteAffectedCaseModel
                {
                    IsAllSelected = true,
                    DeSelectedRowKeys = new List<string>()
                };
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);
                var result = await f.Subject.DeleteAffectedCases(data.@case.Id, deleteAffectedCaseModel);
                Assert.Equal("success", result.Result);
                Assert.Equal(0, result.CannotDeleteCaselistIds.Count);
            }

            [Fact]
            public async Task ShouldDeleteRelatedCasesAndNewOwnersWhenDeletingAffectedCases()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var data = SetupData(true);
                var caseRelation = new CaseRelation {Description = KnownRelations.AssignmentRecordal}.In(Db);
                new RelatedCase(data.@case.Id, null, null, caseRelation, data.relatedCase1.Id).In(Db);
                new RelatedCase(data.@case.Id, null, null, caseRelation, data.relatedCase2.Id).In(Db);
                var element = new Element {Code = KnownRecordalElementValues.NewName, Id = 1}.In(Db);
                new RecordalStepElement {CaseId = data.@case.Id, EditAttribute = KnownRecordalEditAttributes.Mandatory, Element = element, RecordalStepId = 1, NameTypeCode = KnownNameTypes.Owner, ElementValue = "1,2"}.In(Db);

                var relatedCase1 = (Case) data.relatedCase1;
                var relatedCase2 = (Case) data.relatedCase2;
                var rowKeys = new List<string>
                {
                    data.@case.Id + "^" + relatedCase1.Id + "^" + relatedCase1.CountryId + "^" + relatedCase1.CurrentOfficialNumber,
                    data.@case.Id + "^" + relatedCase2.Id + "^" + relatedCase2.CountryId + "^" + relatedCase2.CurrentOfficialNumber
                };

                var deleteAffectedCaseModel = new DeleteAffectedCaseModel
                {
                    SelectedRowKeys = rowKeys
                };
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);
                var result = await f.Subject.DeleteAffectedCases(data.@case.Id, deleteAffectedCaseModel);
                Assert.Equal("success", result.Result);
                f.Helper.Received(2).RemoveRelatedCase(Arg.Any<Case>(), data.relatedCase1, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CaseRelation>(), Arg.Any<CaseRelation>());
                f.Helper.Received(1).RemoveRelatedCase(Arg.Any<Case>(), data.relatedCase2, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CaseRelation>(), Arg.Any<CaseRelation>());
                f.Helper.Received(1).RemoveNewOwners(relatedCase1, "1,2");
                f.Helper.Received(1).RemoveNewOwners(relatedCase2, "1,2");
            }

            [Fact]
            public async Task ShouldNotDeleteDeselectedIds()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var data = SetupData(true);
                var relatedCase1 = (Case) data.relatedCase1;
                var relatedCase2 = (Case) data.relatedCase2;
                var rowKeys = new List<string>
                {
                    data.@case.Id + "^" + relatedCase1.Id + "^" + relatedCase1.CountryId + "^" + relatedCase1.CurrentOfficialNumber,
                    data.@case.Id + "^" + relatedCase2.Id + "^" + relatedCase2.CountryId + "^" + relatedCase2.CurrentOfficialNumber
                };

                var deleteAffectedCaseModel = new DeleteAffectedCaseModel
                {
                    IsAllSelected = true,
                    DeSelectedRowKeys = rowKeys
                };
                var affectedCases = Db.Set<RecordalAffectedCase>().Where(_ => _.RelatedCaseId != relatedCase1.Id || _.RelatedCaseId != relatedCase2.Id);
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);
                var result = await f.Subject.DeleteAffectedCases(data.@case.Id, deleteAffectedCaseModel);
                Assert.Equal("success", result.Result);
                Assert.Equal(0, result.CannotDeleteCaselistIds.Count);
            }

            [Fact]
            public async Task ShouldNotDeleteRecordedAffectedCases()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var data = SetupData(false);
                var relatedCase1 = (Case) data.relatedCase1;
                var relatedCase2 = (Case) data.relatedCase2;
                var rowKeys = new List<string>
                {
                    data.@case.Id + "^" + relatedCase1.Id + "^" + relatedCase1.CountryId + "^" + relatedCase1.CurrentOfficialNumber,
                    data.@case.Id + "^" + relatedCase2.Id + "^" + relatedCase2.CountryId + "^" + relatedCase2.CurrentOfficialNumber
                };
                var deleteAffectedCaseModel = new DeleteAffectedCaseModel
                {
                    SelectedRowKeys = rowKeys,
                    IsAllSelected = false
                };
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);
                var result = await f.Subject.DeleteAffectedCases(data.@case.Id, deleteAffectedCaseModel);
                Assert.Equal("partialComplete", result.Result);
                Assert.Equal(1, result.CannotDeleteCaselistIds.Count);
            }

            [Fact]
            public async Task ShouldReturnErrorWhenNoAffectedCaseDeleted()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var data = SetupData(false);
                data.recordalAffectedCase2.Status = AffectedCaseStatus.Recorded;
                data.recordalAffectedCase3.Status = AffectedCaseStatus.Recorded;
                var relatedCase1 = (Case) data.relatedCase1;
                var relatedCase2 = (Case) data.relatedCase2;
                var rowKeys = new List<string>
                {
                    data.@case.Id + "^" + relatedCase1.Id + "^" + relatedCase1.CountryId + "^" + relatedCase1.CurrentOfficialNumber,
                    data.@case.Id + "^" + relatedCase2.Id + "^" + relatedCase2.CountryId + "^" + relatedCase2.CurrentOfficialNumber
                };

                var deleteAffectedCaseModel = new DeleteAffectedCaseModel
                {
                    SelectedRowKeys = rowKeys,
                    IsAllSelected = false
                };
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);
                var result = await f.Subject.DeleteAffectedCases(data.@case.Id, deleteAffectedCaseModel);
                Assert.Equal("error", result.Result);
                Assert.Equal(rowKeys.Count, result.CannotDeleteCaselistIds.Count);
            }
        }

        public class AddAffectedCases : FactBase
        {
            [Fact]
            public async Task ShouldAddExternalCase()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var country = new CountryBuilder {Id = "AU"}.Build().In(Db);
                var type1 = new RecordalType {Id = 1, RecordalTypeName = "Change of Owner"}.In(Db);
                new RecordalStep {CaseId = @case.Id, Id = 1, TypeId = type1.Id, RecordalType = type1, StepId = 1}.In(Db);
                var model = new RecordalAffectedCaseRequest
                {
                    CaseId = @case.Id,
                    Jurisdiction = country.Id,
                    OfficialNo = "777777",
                    RecordalSteps = new List<RecordalStepAddModel> {new RecordalStepAddModel {RecordalTypeNo = type1.Id, RecordalStepSequence = 1}}
                };

                await f.Subject.AddRecordalAffectedCases(model);
                var affectedCase = Db.Set<RecordalAffectedCase>().LastOrDefault();
                Assert.NotNull(affectedCase);
                Assert.Equal(@case.Id, affectedCase.CaseId);
                Assert.Equal(model.OfficialNo, affectedCase.OfficialNumber);
                Assert.Equal(country.Id, affectedCase.CountryId);
                Assert.Equal(type1.Id, affectedCase.RecordalTypeNo);
                Assert.Equal(AffectedCasesStatus.NotFiled, affectedCase.Status);
            }

            [Fact]
            public async Task ShouldAddInternalCases()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var case1 = new CaseBuilder().Build().In(Db);
                var case2 = new CaseBuilder().Build().In(Db);
                var type1 = new RecordalType {Id = 1, RecordalTypeName = "Change of Owner"}.In(Db);
                new RecordalStep {CaseId = @case.Id, Id = 1, TypeId = type1.Id, RecordalType = type1, StepId = 1}.In(Db);
                var model = new RecordalAffectedCaseRequest
                {
                    CaseId = @case.Id,
                    RelatedCases = new[] {case1.Id, case2.Id},
                    RecordalSteps = new List<RecordalStepAddModel> {new RecordalStepAddModel {RecordalTypeNo = type1.Id, RecordalStepSequence = 1}}
                };

                await f.Subject.AddRecordalAffectedCases(model);
                Assert.Equal(2, Db.Set<RecordalAffectedCase>().Count());
                var affectedCase = Db.Set<RecordalAffectedCase>().FirstOrDefault();
                Assert.NotNull(affectedCase);
                Assert.Equal(@case.Id, affectedCase.CaseId);
                Assert.Equal(case1.Id, affectedCase.RelatedCaseId);
                Assert.Equal(type1.Id, affectedCase.RecordalTypeNo);
                Assert.Equal(AffectedCasesStatus.NotFiled, affectedCase.Status);
            }

            [Fact]
            public async Task ShouldAddRelatedCaseAndNewOwners()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var case1 = new CaseBuilder().Build().In(Db);
                var case2 = new CaseBuilder().Build().In(Db);
                var type1 = new RecordalType {Id = 1, RecordalTypeName = "Change of Owner"}.In(Db);
                new RecordalStep {CaseId = @case.Id, Id = 1, TypeId = type1.Id, RecordalType = type1, StepId = 1}.In(Db);
                var element = new Element {Code = KnownRecordalElementValues.NewName, Id = 1}.In(Db);
                new RecordalStepElement {CaseId = @case.Id, EditAttribute = KnownRecordalEditAttributes.Mandatory, Element = element, RecordalStepId = 1, NameTypeCode = KnownNameTypes.Owner, ElementValue = "1,2"}.In(Db);

                var model = new RecordalAffectedCaseRequest
                {
                    CaseId = @case.Id,
                    RelatedCases = new[] {case1.Id, case2.Id},
                    RecordalSteps = new List<RecordalStepAddModel> {new RecordalStepAddModel {RecordalTypeNo = type1.Id, RecordalStepSequence = 1}}
                };

                await f.Subject.AddRecordalAffectedCases(model);
                Assert.Equal(2, Db.Set<RecordalAffectedCase>().Count());
                f.Helper.Received(1).AddRelatedCase(Arg.Any<Case>(), case1, null, null, Arg.Any<CaseRelation>(), Arg.Any<CaseRelation>(), Arg.Any<int>());
                f.Helper.Received(1).AddRelatedCase(Arg.Any<Case>(), case2, null, null, Arg.Any<CaseRelation>(), Arg.Any<CaseRelation>(), Arg.Any<int>());
                f.Helper.Received(2).AddNewOwners(Arg.Any<Case>(), "1,2");
            }
        }

        public class AddAffectedCaseValidation : FactBase
        {
            [Fact]
            public async Task ShouldReturnCasesWhichMatchesCountryAndOfficialNo()
            {
                var countryCode = "AU";
                var officialNo = "034 034.4";
                var @case = new CaseBuilder {CountryCode = countryCode}.Build().In(Db);
                new CaseBuilder {CountryCode = countryCode}.Build().In(Db);
                new OfficialNumberBuilder {Case = @case, OfficialNo = officialNo}.Build().In(Db);
                new CaseIndexes {CaseId = @case.Id, GenericIndex = "0340344", Source = CaseIndexSource.OfficialNumbers}.In(Db);
                new CaseIndexes {CaseId = @case.Id, GenericIndex = officialNo, Source = CaseIndexSource.OfficialNumbers}.In(Db);

                var f = new AffectedCasesMaintenanceFixture(Db);

                var result = (await f.Subject.AddAffectedCaseValidation(new ExternalAffectedCaseValidateModel {Country = countryCode, OfficialNo = officialNo})).ToArray();
                Assert.Equal(1, result.Length);
                Assert.Equal(@case.Id, result[0].Key);
                Assert.Equal(@case.Irn, result[0].Code);

                result = (await f.Subject.AddAffectedCaseValidation(new ExternalAffectedCaseValidateModel {Country = countryCode, OfficialNo = "0340344"})).ToArray();
                Assert.Equal(1, result.Length);
                Assert.Equal(@case.Id, result[0].Key);
            }

            [Fact]
            public async Task ShouldReturnNullIfCountryOrOfficialNoNotThere()
            {
                var f = new AffectedCasesMaintenanceFixture(Db);
                var result = await f.Subject.AddAffectedCaseValidation(new ExternalAffectedCaseValidateModel());
                Assert.Null(result);

                result = await f.Subject.AddAffectedCaseValidation(new ExternalAffectedCaseValidateModel {Country = Fixture.String()});
                Assert.Null(result);
            }
        }
    }
}