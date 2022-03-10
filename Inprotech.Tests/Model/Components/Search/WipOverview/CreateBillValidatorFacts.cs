using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Search.WipOverview;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Search.WipOverview
{
    public class CreateBillValidatorFacts
    {
        public class ValidateMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnPreventBillingAndNoDebtorErrors()
            {
                var f = new CreateBillValidatorFixture(Db);

                var data = SetupData();
                var requests = new List<CreateBillRequest>
                {
                    new() { CaseKey = data.PreventBillingCase.Id, DebtorKey = Fixture.Integer() },
                    new() { CaseKey = data.Case1.Id, DebtorKey = Fixture.Integer() },
                    new() { CaseKey = data.Case2.Id, AllocatedDebtorKey = Fixture.Integer() }
                };

                var result = (await f.Subject.Validate(requests, CreateBillValidationType.MultipleBill)).ToArray();
                Assert.True(result.Any(x => x.ErrorCode == "AC113"));
                Assert.True(result.Any(x => x.ErrorCode == "AC138"));
                Assert.Equal(2, result.Length);
            }

            [Fact]
            public async Task ShouldReturnMultipleDebtorAndCaseKeysErrors()
            {
                var f = new CreateBillValidatorFixture(Db);

                var data = SetupData();
                var requests = new List<CreateBillRequest>
                {
                    new() { DebtorKey = Fixture.Integer() },
                    new() { DebtorKey = Fixture.Integer() },
                    new() { CaseKey = data.Case1.Id, DebtorKey = Fixture.Integer() },
                    new() { CaseKey = data.Case2.Id, DebtorKey = Fixture.Integer(), AllocatedDebtorKey = Fixture.Integer() }
                };

                var result = (await f.Subject.Validate(requests, CreateBillValidationType.SingleBill)).ToArray();
                Assert.True(result.Any(x => x.ErrorCode == "AC114"));
                Assert.True(result.Any(x => x.ErrorCode == "AC115"));
                Assert.Equal(2, result.Length);
            }

            [Fact]
            public async Task ShouldReturnCaseTypeInternalError()
            {
                var f = new CreateBillValidatorFixture(Db);

                var data = SetupData();
                var requests = new List<CreateBillRequest>
                {
                    new() { CaseKey = data.Case1.Id, DebtorKey = Fixture.Integer() },
                    new() { CaseKey = data.CaseWithInternalType.Id, DebtorKey = Fixture.Integer() }
                };
                string caseTypeInternal = data.CaseTypeInternal.Code;
                f.SiteControlReader.Read<string>(SiteControls.CaseTypeInternal).Returns(caseTypeInternal);

                var result = (await f.Subject.Validate(requests, CreateBillValidationType.SingleBill)).ToArray();
                Assert.True(result.Any(x => x.ErrorCode == "AC116"));
                Assert.Equal(1, result.Length);
            }

            [Fact]
            public async Task ShouldReturnAllocatedDebtorError()
            {
                var f = new CreateBillValidatorFixture(Db);

                var data = SetupData();
                var debtorKey = Fixture.Integer();
                var requests = new List<CreateBillRequest>
                {
                    new() { CaseKey = data.Case1.Id, DebtorKey = debtorKey },
                    new() { CaseKey = data.Case2.Id, DebtorKey = debtorKey, AllocatedDebtorKey = Fixture.Integer() },
                    new() { CaseKey = data.Case2.Id, DebtorKey = debtorKey, AllocatedDebtorKey = Fixture.Integer() }
                };
                f.SiteControlReader.Read<bool>(SiteControls.WIPSplitMultiDebtor).Returns(true);
                var result = (await f.Subject.Validate(requests, CreateBillValidationType.SingleBill)).ToArray();
                Assert.True(result.Any(x => x.ErrorCode == "AC219"));
                Assert.Equal(1, result.Length);
            }

            [Fact]
            public async Task ShouldReturnNoError()
            {
                var f = new CreateBillValidatorFixture(Db);

                var data = SetupData();
                var debtorKey = Fixture.Integer();
                var requests = new List<CreateBillRequest>
                {
                    new() { CaseKey = data.Case1.Id, DebtorKey = debtorKey },
                    new() { CaseKey = data.Case2.Id, DebtorKey = debtorKey },
                    new() { CaseKey = data.Case2.Id, DebtorKey = debtorKey, AllocatedDebtorKey = Fixture.Integer() }
                };

                string caseTypeInternal = data.CaseTypeInternal.Code;
                f.SiteControlReader.Read<string>(SiteControls.CaseTypeInternal).Returns(caseTypeInternal);

                f.SiteControlReader.Read<bool>(SiteControls.WIPSplitMultiDebtor).Returns(true);
                var result = (await f.Subject.Validate(requests, CreateBillValidationType.SingleBill)).ToArray();
                Assert.False(result.Any());
            }

            dynamic SetupData()
            {
                var country = new Country(Fixture.UniqueName(), Fixture.String()).In(Db);
                var caseType = new CaseType(Fixture.UniqueName(), Fixture.String()).In(Db);
                var caseTypeInternal = new CaseType(Fixture.UniqueName(), Fixture.String()).In(Db);
                var propertyType = new PropertyType(Fixture.UniqueName(), Fixture.String()).In(Db);
                var status = new Status(Fixture.Short(), Fixture.String()) { PreventBilling = true }.In(Db);

                var preventBillingCase = new Case(Fixture.String(), country, caseType, propertyType) { StatusCode = status.Id }.In(Db);
                var case1 = new Case(Fixture.String(), country, caseType, propertyType).In(Db);
                var case2 = new Case(Fixture.String(), country, caseType, propertyType).In(Db);
                var caseWithInternalType = new Case(Fixture.String(), country, caseTypeInternal, propertyType).In(Db);

                return new
                {
                    PreventBillingCase = preventBillingCase,
                    Case1 = case1,
                    Case2 = case2,
                    CaseWithInternalType = caseWithInternalType,
                    CaseTypeInternal = caseTypeInternal
                };
            }
        }
    }

    public class CreateBillValidatorFixture : IFixture<ICreateBillValidator>
    {
        public CreateBillValidatorFixture(InMemoryDbContext db = null)
        {
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Subject = new CreateBillValidator(DbContext, SiteControlReader);
        }

        public IDbContext DbContext { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public ICreateBillValidator Subject { get; }
    }
}