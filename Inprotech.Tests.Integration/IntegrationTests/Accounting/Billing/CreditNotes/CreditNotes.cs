using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model.Accounting;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.CreditNotes
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(16)] // Credit Notes is only getting slightly more stable from Release 16
    public class CreditNotes : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }
        
        [Test]
        public void LoadWithSignsReversal()
        {
            var billingData = new DraftBillDataSetup().Setup();

            var bills = DbSetup.Do(x =>
            {
                var wip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalMultiple.Id, billingData.ServiceCharge1.WipCode, -1000)
                    .Wip;
                
                /*
                 * It is expected that an OpenItem is created for each debtor in the Case.
                 * The CaseLocalMultiple contains 2 debtors, so there should be 2 Open Items returned.
                 */
                var openItems = new OpenItemBuilder(x.DbContext)
                {
                    TypeId = ItemType.CreditNote,
                    ReasonCode = "ER",
                    StaffId = billingData.StaffName.Id,
                    StaffProfitCentre = billingData.StaffProfitCentre.Id,
                    EntityId = billingData.EntityId,
                    LocalValue = wip.LocalValue,
                    LocalBalance = wip.Balance.GetValueOrDefault()
                }.BuildDraftBill(billingData.CaseLocalMultiple.Id, wip);
                
                return new
                {
                    WipIncluded = new [] { wip },
                    OpenItems = openItems
                };
            });

            foreach (var openItem in bills.OpenItems)
            {
                /*
                 * The OpenItems here should show individual OpenItemNo, LocalValue, LocalBalance, with sign reversed.
                 */
                var itemModel = BillingService.GetOpenItem(billingData.EntityId, openItem.OpenItemNo);

                CommonAssert.OpenItemAreEqual(new ExpectedOpenItemValues
                {
                    OpenItemNo = openItem.OpenItemNo,
                    ItemDate = openItem.ItemDate,
                    ItemEntityId = openItem.ItemEntityId,
                    ItemTransactionId = openItem.ItemTransactionId,
                    AccountEntityId = openItem.AccountEntityId,
                    AccountDebtorNameId = openItem.AccountDebtorId,
                    BillPercentage = openItem.BillPercentage,
                    StaffProfitCentre = openItem.StaffProfitCentre,
                    
                    TypeId = (ItemType) openItem.TypeId,
                    Status = (TransactionStatus) openItem.Status,
                    
                    LocalBalance = openItem.LocalBalance * -1,  /* sign reversed for UI */
                    LocalValue = openItem.LocalValue * -1,  /* sign reversed for UI */
                
                    ReferenceText = openItem.ReferenceText, 
                    Regarding = openItem.Regarding, 
                    StatementRef = openItem.StatementRef, 
                    Scope = openItem.Scope, 
                }, itemModel);
            }
        }
    }
}
