
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Tax;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.NewDebitNotes
{
    [TestFixture]
    [Category(Categories.Integration)]
    public class WipSelection : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        [Test]
        public void PreventSelectionOfWipItemsAlreadyLockedOnOtherBills()
        {
            var fixture = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var wipAvailableForThisBill = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalSingle.Id, billingData.ServiceCharge1.WipCode, 1000);

                var wipLockedOnAnotherBill = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalSingle.Id, billingData.ServiceCharge1.WipCode, 2000, -200);

                var otherDraftBill = new OpenItemBuilder(x.DbContext)
                {
                    StaffId = billingData.StaffName.Id,
                    StaffProfitCentre = billingData.StaffProfitCentre.Id,
                    EntityId = billingData.EntityId,
                    LocalValue = wipLockedOnAnotherBill.Wip.LocalValue,
                    LocalBalance = wipLockedOnAnotherBill.Wip.Balance.GetValueOrDefault()
                }.BuildDraftBill(billingData.CaseLocalSingle.Id, wipLockedOnAnotherBill.Wip, wipLockedOnAnotherBill.Discount);

                x.DbContext.SaveChanges();

                return new
                {
                    billingData.Today,
                    billingData.EntityId,
                    Case = billingData.CaseLocalSingle,
                    RaisedByStaffId = billingData.StaffName.Id,
                    BillingData = billingData,
                    WipAvailableForThisBill = wipAvailableForThisBill.Wip,
                    WipLockedOnAnotherBill = wipLockedOnAnotherBill.Wip,
                    DiscountWipLockedOnAnotherBill = wipLockedOnAnotherBill.Discount,
                    OtherDraftBillOpenItemNo = otherDraftBill.Single().OpenItemNo,
                    ServiceChargeWipTemplate = billingData.ServiceCharge1,
                    ServiceChargeWipType = billingData.ServiceCharge1.WipType,
                    ServiceChargeWipCategory = billingData.ServiceCharge1.WipType.Category,
                    /* this is simplified for test data retrieval, it should be based on effective date, country (or fallback to 'ZZZ') */
                    ServiceChargeTaxRate = x.DbContext.Set<TaxRatesCountry>().Single(_ => _.TaxCode == billingData.ServiceCharge1.TaxCode)
                };
            });

            /*
             * Data Setup
             * The case has a local debtor
             * - two wip item are recorded against the case
             * -- 1000 unlocked
             * -- 2000 with 200 discount locked to a different draft bill
             *
             * Notable Test Results Expectations
             * - given that wip is locked onto another bill, those wip will not be available for selection.
             * - the wip available for selection should have Billed fields null and no BilledItem.
             */

            var availableWipItems = BillingService.GetAvailableWipForCase(fixture.EntityId, null,
                                                                          new[] { fixture.Case.Id },
                                                                          fixture.Case.Debtor1().NameId,
                                                                          fixture.RaisedByStaffId,
                                                                          ItemType.DebitNote,
                                                                          fixture.Today).ToArray();

            Assert.Null(availableWipItems.SingleOrDefault(_ => _.EntityId == fixture.WipLockedOnAnotherBill.EntityId
                                                               && _.TransactionId == fixture.WipLockedOnAnotherBill.TransactionId
                                                               && _.WipSeqNo == fixture.WipLockedOnAnotherBill.WipSequenceNo), "Should not return the wip item locked in another draft wip");

            Assert.Null(availableWipItems.SingleOrDefault(_ => _.EntityId == fixture.DiscountWipLockedOnAnotherBill.EntityId
                                                               && _.TransactionId == fixture.DiscountWipLockedOnAnotherBill.TransactionId
                                                               && _.WipSeqNo == fixture.DiscountWipLockedOnAnotherBill.WipSequenceNo), "Should not return the discount wip item locked in another draft wip");

            CommonAssert.AvailableWipIsEqual(new ExpectedWipValues
            {
                Balance = fixture.WipAvailableForThisBill.Balance,

                LocalBilled = null, /* this is unlocked so it is null */
                BillItemEntityId = null, /* this is unlocked so it is null */
                BillItemTransactionId = null, /* this is unlocked so it is null */
                BillLineNo = null, /* this is unlocked so it is null */

                CaseId = fixture.WipAvailableForThisBill.CaseId,
                CaseRef = fixture.WipAvailableForThisBill.Case.Irn,
                WipCode = fixture.WipAvailableForThisBill.WipCode,

                WipSequenceNo = fixture.WipAvailableForThisBill.WipSequenceNo,
                EntityId = fixture.WipAvailableForThisBill.EntityId,
                TransactionId = fixture.WipAvailableForThisBill.TransactionId,
                TransactionDate = fixture.WipAvailableForThisBill.TransactionDate,

                NarrativeId = fixture.WipAvailableForThisBill.NarrativeId,
                ShortNarrative = fixture.WipAvailableForThisBill.ShortNarrative,

                WipTypeId = fixture.ServiceChargeWipTemplate.WipTypeId,
                Description = fixture.ServiceChargeWipTemplate.Description,
                WipCategory = fixture.ServiceChargeWipTemplate.WipType.CategoryId,
                TaxCode = fixture.ServiceChargeWipTemplate.TaxCode,
                TaxRate = fixture.ServiceChargeTaxRate.Rate,
                WipCategorySortOrder = fixture.ServiceChargeWipCategory.CategorySortOrder.GetValueOrDefault(),
                WipTypeSortOrder = fixture.ServiceChargeWipType.WipTypeSortOrder.GetValueOrDefault()
            }, availableWipItems.Single(_ => _.EntityId == fixture.WipAvailableForThisBill.EntityId
                                             && _.TransactionId == fixture.WipAvailableForThisBill.TransactionId
                                             && _.WipSeqNo == fixture.WipAvailableForThisBill.WipSequenceNo), "Unlocked Wip");
        }
    }
}
