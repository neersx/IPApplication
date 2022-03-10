using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing
{
    public class BillingUserPermissionSettingsResolverFacts
    {
        readonly IFunctionSecurityProvider _functionSecurityProvider = Substitute.For<IFunctionSecurityProvider>();
        readonly ISiteControlReader _siteControlReader = Substitute.For<ISiteControlReader>();
        readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

        BillingUserPermissionSettingsResolver CreateSubject(decimal? writeDownLimit = null)
        {
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User { WriteDownLimit = writeDownLimit });

            return new BillingUserPermissionSettingsResolver(_siteControlReader, _taskSecurityProvider, _functionSecurityProvider, securityContext);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public async Task ShouldReturnCanDeleteDebitNoteBasedOnTaskSecurity(bool canDeleteDebitNote, bool expectedCanDeleteDebitNote)
        {
            _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Delete)
                                 .Returns(canDeleteDebitNote);

            var r = await CreateSubject().Resolve();

            Assert.Equal(expectedCanDeleteDebitNote, r.CanDeleteDebitNote);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public async Task ShouldReturnCanDeleteCreditNoteBasedOnTaskSecurity(bool canDeleteCreditNote, bool expectedCanDeleteCreditNote)
        {
            _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Delete)
                                 .Returns(canDeleteCreditNote);

            var r = await CreateSubject().Resolve();

            Assert.Equal(expectedCanDeleteCreditNote, r.CanDeleteCreditNote);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public async Task ShouldReturnCanAdjustForeignBillValueBasedOnTaskSecurity(bool canAdjustForeignBillValue, bool expectedCanAdjustForeignBillValue)
        {
            _taskSecurityProvider.HasAccessTo(ApplicationTask.AdjustForeignBillValue)
                                 .Returns(canAdjustForeignBillValue);

            var r = await CreateSubject().Resolve();

            Assert.Equal(expectedCanAdjustForeignBillValue, r.CanAdjustForeignBillValue);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public async Task ShouldReturnCanAdjustForeignBillLineValuesBasedOnTaskSecurity(bool canAdjustForeignBillLineValues, bool expectedCanAdjustForeignBillLineValues)
        {
            _taskSecurityProvider.HasAccessTo(ApplicationTask.AdjustForeignBillLineValues)
                                 .Returns(canAdjustForeignBillLineValues);

            var r = await CreateSubject().Resolve();

            Assert.Equal(expectedCanAdjustForeignBillLineValues, r.CanAdjustForeignBillLineValues);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public async Task ShouldReturnCanCreditBillBasedOnUserFunctionSecurity(bool canCreditBill, bool expectedCanCreditBill)
        {

            _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create)
                                 .Returns(true);
            _functionSecurityProvider.BestFit(BusinessFunction.Billing, Arg.Any<User>(), Arg.Any<int>())
                                     .Returns(new FunctionPrivilege
                                     {
                                         CanCredit = canCreditBill
                                     });

            var r = await CreateSubject().Resolve();

            Assert.Equal(expectedCanCreditBill, r.CanCreditBill);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public async Task ShouldReturnCanFinaliseBillBasedOnUserFunctionSecurity(bool canFinaliseBill, bool expectedCanFinaliseBill)
        {
            _functionSecurityProvider.BestFit(BusinessFunction.Billing, Arg.Any<User>(), Arg.Any<int>())
                                     .Returns(new FunctionPrivilege
                                     {
                                         CanFinalise = canFinaliseBill
                                     });

            var r = await CreateSubject().Resolve();

            Assert.Equal(expectedCanFinaliseBill, r.CanFinaliseBill);
        }

        [Theory]
        [InlineData(true, BillReversalTypeAllowed.CurrentPeriodReversalAllowed, BillReversalTypeAllowed.CurrentPeriodReversalAllowed)]
        [InlineData(true, BillReversalTypeAllowed.ReversalNotAllowed, BillReversalTypeAllowed.ReversalNotAllowed)]
        [InlineData(true, BillReversalTypeAllowed.ReversalAllowed, BillReversalTypeAllowed.ReversalAllowed)]
        [InlineData(false, BillReversalTypeAllowed.CurrentPeriodReversalAllowed, BillReversalTypeAllowed.ReversalNotAllowed)]
        [InlineData(false, BillReversalTypeAllowed.ReversalNotAllowed, BillReversalTypeAllowed.ReversalNotAllowed)]
        [InlineData(false, BillReversalTypeAllowed.ReversalAllowed, BillReversalTypeAllowed.ReversalNotAllowed)]
        public async Task ShouldReturnBillReversalSetting(bool hasFunctionSecurityToReverseBill, BillReversalTypeAllowed billReversalTypeAllowedSetting, BillReversalTypeAllowed expectedBillReversalTypeAllowed)
        {
            _siteControlReader.Read<int?>(SiteControls.BillReversalDisabled).Returns((int)billReversalTypeAllowedSetting);

            _functionSecurityProvider.BestFit(BusinessFunction.Billing, Arg.Any<User>(), Arg.Any<int>())
                                     .Returns(new FunctionPrivilege
                                     {
                                         CanReverse = hasFunctionSecurityToReverseBill
                                     });

            var r = await CreateSubject().Resolve();

            Assert.Equal(expectedBillReversalTypeAllowed, r.CanReverseBill);
        }

        [Fact]
        public async Task ShouldReturnWriteDownLimit()
        {
            var writeDownLimit = Fixture.Decimal();

            var r = await CreateSubject(writeDownLimit).Resolve();

            Assert.Equal(writeDownLimit, r.WriteDownLimit);
        }
    }
}