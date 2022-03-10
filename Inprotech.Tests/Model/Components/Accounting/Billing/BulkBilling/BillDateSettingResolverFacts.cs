using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.BulkBilling;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.BulkBilling
{
    public class BillDateSettingResolverFacts : FactBase
    {
        BillDateSettingsResolver CreateSubject(bool billDatesForwardOnly, bool? billDateChange = null)
        {
            var siteControlReader = Substitute.For<ISiteControlReader>();
            siteControlReader.Read<bool>(SiteControls.BillDatesForwardOnly)
                             .Returns(billDatesForwardOnly);

            siteControlReader.Read<bool>(SiteControls.BillDateChange)
                             .Returns(billDateChange.GetValueOrDefault());

            return new BillDateSettingsResolver(Db, siteControlReader);
        }

        [Fact]
        public async Task ShouldNotReturnLastFinalisedDateIfBillDatesForwardOnlyIsNotSet()
        {
            const bool billDateForwardOnly = false;

            var r = await CreateSubject(billDateForwardOnly).Resolve();

            Assert.Null(r.LastFinalisedDate);
        }

        [Theory]
        [InlineData(ItemType.CreditNote)]
        [InlineData(ItemType.DebitNote)]
        [InlineData(ItemType.InternalCreditNote)]
        [InlineData(ItemType.InternalDebitNote)]
        public async Task ShouldReturnItemDateForEligibleBillRelatedOpenItems(ItemType eligibleBillRelatedOpenItem)
        {
            const bool billDateForwardOnly = true;

            new OpenItemBuilder(Db)
            {
                Status = TransactionStatus.Active,
                TypeId = eligibleBillRelatedOpenItem,
                ItemDate = Fixture.Today()
            }.Build().In(Db);

            var r = await CreateSubject(billDateForwardOnly).Resolve();

            Assert.Equal(Fixture.Today(), r.LastFinalisedDate);
        }

        [Theory]
        [InlineData(ItemType.CreditJournal)]
        [InlineData(ItemType.DebitJournal)]
        [InlineData(ItemType.Prepayment)]
        [InlineData(ItemType.UnallocatedCash)]
        public async Task ShouldNotReturnItemDateForIneligibleOpenItems(ItemType ineligibleOpenItem)
        {
            const bool billDateForwardOnly = true;

            new OpenItemBuilder(Db)
            {
                Status = TransactionStatus.Active,
                TypeId = ineligibleOpenItem,
                ItemDate = Fixture.Today()
            }.Build().In(Db);

            var r = await CreateSubject(billDateForwardOnly).Resolve();

            Assert.Null(r.LastFinalisedDate);
        }

        [Fact]
        public async Task ShouldReturnMostRecentOpenItemDate()
        {
            const bool billDateForwardOnly = true;

            var expected = new OpenItemBuilder(Db)
            {
                Status = TransactionStatus.Active,
                TypeId = ItemType.CreditNote,
                ItemDate = Fixture.Today()
            }.Build().In(Db);

            new OpenItemBuilder(Db)
            {
                Status = TransactionStatus.Active,
                TypeId = ItemType.DebitNote,
                ItemDate = Fixture.PastDate()
            }.Build().In(Db);

            var r = await CreateSubject(billDateForwardOnly).Resolve();

            Assert.Equal(expected.ItemDate, r.LastFinalisedDate);
        }

        [Theory]
        [InlineData(null, false)]
        [InlineData(false, false)]
        [InlineData(true, true)]
        public async Task ShouldReturnBillDateChangeSiteControlValue(bool? billDateChange, bool expectedBillDateChangeValue)
        {
            const bool billDateForwardOnly = true;

            var r = await CreateSubject(billDateForwardOnly, billDateChange).Resolve();

            Assert.Equal(expectedBillDateChangeValue, r.ShouldChangeBillDateIfNotToday);
        }
    }
}