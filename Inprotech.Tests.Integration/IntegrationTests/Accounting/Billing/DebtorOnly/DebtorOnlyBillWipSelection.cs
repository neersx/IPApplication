using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Accounting;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.DebtorOnly
{
    [TestFixture]
    [Category(Categories.Integration)]
    public class DebtorOnlyBillWipSelection : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }
        
        [Test]
        public void AllowSelectionOfDebtorOnlyWip()
        {
            var fixture = new DebtorOnlyBillDataSetup().Setup();
            
            /*
             * Data Setup
             * The local debtor has two wip item recorded against him
             * -- 1000 unlocked
             * -- 10 discount
             *
             * Notable Test Results Expectations
             * - given that wip is locked onto another bill, those wip will not be available for selection.
             * - the wip available for selection should have Billed fields null and no BilledItem.
             */

            var availableWipItems = BillingService.GetAvailableWipForDebtor(fixture.EntityId, null,
                                                                          fixture.LocalDebtor.Id,
                                                                          fixture.StaffName.Id,
                                                                          ItemType.DebitNote,
                                                                          fixture.Today).ToArray();

            CommonAssert.AvailableWipIsEqual(new ExpectedWipValues
            {
                Balance = fixture.DebtorOnlyWipLocalDebtor.Balance,

                LocalBilled = null, /* this is unlocked so it is null */
                BillItemEntityId = null, /* this is unlocked so it is null */
                BillItemTransactionId = null, /* this is unlocked so it is null */
                BillLineNo = null, /* this is unlocked so it is null */
                
                AccountClientId = fixture.LocalDebtor.Id,
                WipCode = fixture.DebtorOnlyWipLocalDebtor.WipCode,

                WipSequenceNo = fixture.DebtorOnlyWipLocalDebtor.WipSequenceNo,
                EntityId = fixture.DebtorOnlyWipLocalDebtor.EntityId,
                TransactionId = fixture.DebtorOnlyWipLocalDebtor.TransactionId,
                TransactionDate = fixture.DebtorOnlyWipLocalDebtor.TransactionDate,

                NarrativeId = fixture.DebtorOnlyWipLocalDebtor.NarrativeId,
                ShortNarrative = fixture.DebtorOnlyWipLocalDebtor.ShortNarrative,

                WipTypeId = fixture.ServiceChargeWipTemplate.WipTypeId,
                Description = fixture.ServiceChargeWipTemplate.Description,
                WipCategory = fixture.ServiceChargeWipTemplate.WipType.CategoryId,
                TaxCode = fixture.ServiceChargeWipTemplate.TaxCode,
                TaxRate = fixture.ServiceChargeTaxRate.Rate,
                WipCategorySortOrder = fixture.ServiceChargeWipCategory.CategorySortOrder.GetValueOrDefault(),
                WipTypeSortOrder = fixture.ServiceChargeWipType.WipTypeSortOrder.GetValueOrDefault()
            }, availableWipItems.Single(_ => _.EntityId == fixture.DebtorOnlyWipLocalDebtor.EntityId
                                             && _.TransactionId == fixture.DebtorOnlyWipLocalDebtor.TransactionId
                                             && _.WipSeqNo == fixture.DebtorOnlyWipLocalDebtor.WipSequenceNo), "Unlocked Wip");

            CommonAssert.AvailableWipIsEqual(new ExpectedWipValues
            {
                Balance = fixture.DebtorOnlyWipDiscountLocalDebtor.Balance,

                LocalBilled = null, /* this is unlocked so it is null */
                BillItemEntityId = null, /* this is unlocked so it is null */
                BillItemTransactionId = null, /* this is unlocked so it is null */
                BillLineNo = null, /* this is unlocked so it is null */

                AccountClientId = fixture.LocalDebtor.Id,
                WipCode = fixture.DebtorOnlyWipDiscountLocalDebtor.WipCode,

                WipSequenceNo = fixture.DebtorOnlyWipDiscountLocalDebtor.WipSequenceNo,
                EntityId = fixture.DebtorOnlyWipDiscountLocalDebtor.EntityId,
                TransactionId = fixture.DebtorOnlyWipDiscountLocalDebtor.TransactionId,
                TransactionDate = fixture.DebtorOnlyWipDiscountLocalDebtor.TransactionDate,

                NarrativeId = fixture.DebtorOnlyWipDiscountLocalDebtor.NarrativeId,
                ShortNarrative = fixture.DebtorOnlyWipDiscountLocalDebtor.ShortNarrative,

                WipTypeId = fixture.DiscountWipType.Id,
                WipTypeSortOrder = fixture.DiscountWipType.WipTypeSortOrder.GetValueOrDefault(),

                WipCategory = fixture.DiscountWipType.CategoryId,
                WipCategorySortOrder = fixture.ServiceChargeWipCategory.CategorySortOrder.GetValueOrDefault(),
                
                Description = fixture.DiscountWipTemplate.Description,
                TaxCode = fixture.DiscountWipTemplate.TaxCode,
                TaxRate = fixture.DiscountTaxRate.Rate,

                IsDiscount = true

            }, availableWipItems.Single(_ => _.EntityId == fixture.DebtorOnlyWipDiscountLocalDebtor.EntityId
                                             && _.TransactionId == fixture.DebtorOnlyWipDiscountLocalDebtor.TransactionId
                                             && _.WipSeqNo == fixture.DebtorOnlyWipDiscountLocalDebtor.WipSequenceNo), "Unlocked Discount Wip");
        }
    }
}
