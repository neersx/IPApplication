using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.DebitNotes
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class FinalisedDebitNote : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        [Test]
        public void ReviewFinalised()
        {
            var billingData = new DraftBillDataSetup().Setup();

            var bills = DbSetup.Do(x =>
            {
                var localWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalMultiple.Id, billingData.ServiceCharge1.WipCode, 1000);

                var localWipWithDiscount = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalMultiple.Id, billingData.ServiceCharge1.WipCode, 2000, -200);

                var workHistory = from wh in x.DbContext.Set<WorkHistory>()
                                  where wh.EntityId == billingData.EntityId
                                        && (wh.TransactionId == localWipWithDiscount.Wip.TransactionId || wh.TransactionId == localWipWithDiscount.Wip.TransactionId)
                                  select wh;

                /*
                 * Billed WIP are removed and left with new WorkHistory with MovementClass of 'Billed', and CommandID of 'Consume'
                 */
                x.DbContext.Delete(from wip in x.DbContext.Set<WorkInProgress>()
                                   where wip.EntityId == billingData.EntityId
                                         && (wip.TransactionId == localWipWithDiscount.Wip.TransactionId || wip.TransactionId == localWipWithDiscount.Wip.TransactionId)
                                   select wip);

                /*
                 * With WIP Split Multi Debtor = False
                 * It is expected that an OpenItem is created for each debtor in the Case.
                 * The CaseLocalMultiple contains 2 debtors, so there should be 2 Open Items returned.
                 */
                var openItems = new OpenItemBuilder(x.DbContext)
                {
                    StaffId = billingData.StaffName.Id,
                    StaffProfitCentre = billingData.StaffProfitCentre.Id,
                    EntityId = billingData.EntityId,
                    LocalValue = localWip.Wip.LocalValue + localWipWithDiscount.Wip.LocalValue,
                    LocalBalance = localWip.Wip.Balance.GetValueOrDefault() + localWipWithDiscount.Wip.Balance.GetValueOrDefault()
                }.BuildFinalisedBill(billingData.CaseLocalMultiple.Id, workHistory.ToArray());

                return new
                {
                    WorkHistoryIncluded = workHistory,
                    OpenItems = openItems
                };
            });

            foreach (var openItem in bills.OpenItems)
            {
                /*
                 * The OpenItems here should show individual OpenItemNo, LocalValue, LocalBalance.
                 */
                var itemModel = BillingService.GetOpenItem(billingData.EntityId, openItem.OpenItemNo);

                var expected = new ExpectedOpenItemValues(openItem);

                CommonAssert.OpenItemAreEqual(expected, itemModel);
            }
        }
    }
}