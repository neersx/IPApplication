using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model.Accounting;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.DebitNotes
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class MergingDebitNotes : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        [Test]
        public void MergeMultipleSameCurrency()
        {
            var billingData = new DraftBillDataSetup().Setup();

            var bills = DbSetup.Do(x =>
            {
                var foreignWip1 = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseForeignSingle.Id, billingData.ServiceCharge1.WipCode,
                                          1000, foreignCurrency: billingData.ForeignCurrency.Id, exchangeRate: (decimal) 1.2)
                    .Wip;

                var foreignWip2 = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseForeignSingle.Id, billingData.ServiceCharge2.WipCode,
                                          1000, foreignCurrency: billingData.ForeignCurrency.Id, exchangeRate: (decimal) 1.2)
                    .Wip;

                /*
                 * CaseForeignSingle is a single debtor case, so there should only be one OpenItem created.
                 * This OpenItem should have
                 * * Bill Percentage = 100%
                 * * LocalValue = 833.00 (ForeignValue 1000 / ExchangeRate 1.2) 
                 * * LocalBalance = 833.00 (ForeignBalance 1000 / ExchangeRate 1.2) 
                 */
                var openItemForServiceCharge1 = new OpenItemBuilder(x.DbContext)
                {
                    StaffId = billingData.StaffName.Id,
                    StaffProfitCentre = billingData.StaffProfitCentre.Id,
                    EntityId = billingData.EntityId,
                    LocalValue = foreignWip1.LocalValue,
                    LocalBalance = foreignWip1.Balance.GetValueOrDefault(),
                    ForeignValue = foreignWip1.ForeignValue,
                    ForeignBalance = foreignWip1.ForeignBalance,
                    Currency = foreignWip1.ForeignCurrency,
                    ExchangeRate = foreignWip1.ExchangeRate
                }.BuildDraftBill(billingData.CaseForeignSingle.Id, foreignWip1);

                /*
                 * CaseForeignSingle is a single debtor case, so there should only be one OpenItem created.
                 * This OpenItem should have
                 * * Bill Percentage = 100%
                 * * LocalValue = 833.00 (ForeignValue 1000 / ExchangeRate 1.2) 
                 * * LocalBalance = 833.00 (ForeignBalance 1000 / ExchangeRate 1.2) 
                 */
                var openItemForServiceCharge2 = new OpenItemBuilder(x.DbContext)
                {
                    StaffId = billingData.StaffName.Id,
                    StaffProfitCentre = billingData.StaffProfitCentre.Id,
                    EntityId = billingData.EntityId,
                    LocalValue = foreignWip2.LocalValue,
                    LocalBalance = foreignWip2.Balance.GetValueOrDefault(),
                    ForeignValue = foreignWip2.ForeignValue,
                    ForeignBalance = foreignWip2.ForeignBalance,
                    Currency = foreignWip2.ForeignCurrency,
                    ExchangeRate = foreignWip2.ExchangeRate
                }.BuildDraftBill(billingData.CaseForeignSingle.Id, foreignWip2);

                return new
                {
                    WipIncluded = new[] {foreignWip1, foreignWip2},
                    OpenItems = new[]
                    {
                        openItemForServiceCharge1.Single(),
                        openItemForServiceCharge2.Single()
                    }
                };
            });

            var mergedOpenItems = string.Join("|", bills.OpenItems.Select(_ => _.OpenItemNo));
            var itemModel = BillingService.GetOpenItems(mergedOpenItems);

            /*
             * Expectation is that because the currency is the same across the OpenItems, Currency, ForeignBalance and ForeignValue are retained.
             */

            CommonAssert.OpenItemAreEqual(new ExpectedOpenItemValues
            {
                ItemEntityId = bills.OpenItems.First().ItemEntityId,
                AccountEntityId = bills.OpenItems.First().AccountEntityId,
                StaffProfitCentre = bills.OpenItems.First().StaffProfitCentre,

                ItemDate = billingData.Today,

                TypeId = ItemType.DebitNote,
                Status = TransactionStatus.Draft,

                ItemTransactionId = null,
                OpenItemNo = null,

                AccountDebtorNameId = 0, /* TO VERIFY: AccountDebtorNameId isn't copied in OpenItemWorker.cs */
                BillPercentage = 0, /* TO VERIFY: BillPercentage isn't copied in OpenItemWorker.cs */
                LocalBalance = 0, /* TO VERIFY: LocalBalance isn't copied in OpenItemWorker.cs */
                LocalValue = 0, /* TO VERIFY: LocalValue isn't copied in OpenItemWorker.cs */

                ExchangeRate = null, /* TO VERIFY: ExchangeRate isn't copied in OpenItemWorker.cs */
                ExchangeRateVariance = null, /* TO VERIFY: ExchangeRateVariance isn't copied in OpenItemWorker.cs */

                ForeignBalance = 2000, /* sum of both items created above, 1000 each */
                ForeignValue = 2000, /* sum of both items created above, 1000 each */

                Currency = billingData.ForeignCurrency.Id,

                ReferenceText = $"{bills.OpenItems.First().ReferenceText}{Environment.NewLine}{bills.OpenItems.Last().ReferenceText}",
                Regarding = $"{bills.OpenItems.First().Regarding}{Environment.NewLine}{bills.OpenItems.Last().Regarding}",
                StatementRef = $"{bills.OpenItems.First().StatementRef}{Environment.NewLine}{bills.OpenItems.Last().StatementRef}",
                Scope = $"{bills.OpenItems.First().Scope}{Environment.NewLine}{bills.OpenItems.Last().Scope}"
            }, itemModel, "merged");
        }

        [Test]
        public void MergeMultipleDifferentCurrency()
        {
            var billingData = new DraftBillDataSetup().Setup();

            var bills = DbSetup.Do(x =>
            {
                var foreignWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseForeignSingle.Id, billingData.ServiceCharge1.WipCode,
                                          1000, foreignCurrency: billingData.ForeignCurrency.Id, exchangeRate: (decimal) 1.2)
                    .Wip;

                var localWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalSingle.Id, billingData.ServiceCharge2.WipCode, 1000)
                    .Wip;

                /*
                 * CaseForeignSingle is a single debtor case, so there should only be one OpenItem created.
                 * This OpenItem should have
                 * * Bill Percentage = 100%
                 * * LocalValue = 833.00 (ForeignValue 1000 / ExchangeRate 1.2) 
                 * * LocalBalance = 833.00 (ForeignBalance 1000 / ExchangeRate 1.2) 
                 */
                var openItemForServiceCharge1 = new OpenItemBuilder(x.DbContext)
                {
                    StaffId = billingData.StaffName.Id,
                    StaffProfitCentre = billingData.StaffProfitCentre.Id,
                    EntityId = billingData.EntityId,
                    LocalValue = foreignWip.LocalValue,
                    LocalBalance = foreignWip.Balance.GetValueOrDefault(),
                    ForeignValue = foreignWip.ForeignValue,
                    ForeignBalance = foreignWip.ForeignBalance,
                    Currency = foreignWip.ForeignCurrency,
                    ExchangeRate = foreignWip.ExchangeRate
                }.BuildDraftBill(billingData.CaseForeignSingle.Id, foreignWip);

                /*
                 * CaseLocalSingle is a single debtor case, so there should only be one OpenItem created.
                 * This OpenItem should have
                 * * Bill Percentage = 100%
                 * * LocalValue = 1000.00 
                 * * LocalBalance = 1000.00
                 */
                var openItemForServiceCharge2 = new OpenItemBuilder(x.DbContext)
                {
                    StaffId = billingData.StaffName.Id,
                    StaffProfitCentre = billingData.StaffProfitCentre.Id,
                    EntityId = billingData.EntityId,
                    LocalValue = localWip.LocalValue,
                    LocalBalance = localWip.Balance.GetValueOrDefault(),
                    ForeignValue = localWip.ForeignValue,
                    ForeignBalance = localWip.ForeignBalance,
                    Currency = localWip.ForeignCurrency,
                    ExchangeRate = localWip.ExchangeRate
                }.BuildDraftBill(billingData.CaseForeignSingle.Id, localWip);

                return new
                {
                    WipIncluded = new[] {foreignWip, localWip},
                    OpenItems = new[]
                    {
                        openItemForServiceCharge1.Single(),
                        openItemForServiceCharge2.Single()
                    }
                };
            });

            var mergedOpenItems = string.Join("|", bills.OpenItems.Select(_ => _.OpenItemNo));
            var itemModel = BillingService.GetOpenItems(mergedOpenItems);

            /*
             * Expectation is that because the currency is not the same across the OpenItems, Currency, ForeignBalance and ForeignValue are zeroed and null out.
             */

            CommonAssert.OpenItemAreEqual(new ExpectedOpenItemValues
            {
                ItemEntityId = bills.OpenItems.First().ItemEntityId,
                AccountEntityId = bills.OpenItems.First().AccountEntityId,
                StaffProfitCentre = bills.OpenItems.First().StaffProfitCentre,

                ItemDate = billingData.Today,

                TypeId = ItemType.DebitNote,
                Status = TransactionStatus.Draft,

                ItemTransactionId = null,
                OpenItemNo = null,

                AccountDebtorNameId = 0, /* TO VERIFY: AccountDebtorNameId isn't copied in OpenItemWorker.cs */
                BillPercentage = 0, /* TO VERIFY: BillPercentage isn't copied in OpenItemWorker.cs */
                LocalBalance = 0, /* TO VERIFY: LocalBalance isn't copied in OpenItemWorker.cs */
                LocalValue = 0, /* TO VERIFY: LocalValue isn't copied in OpenItemWorker.cs */

                ExchangeRate = null, /* TO VERIFY: ExchangeRate isn't copied in OpenItemWorker.cs */
                ExchangeRateVariance = null, /* TO VERIFY: ExchangeRateVariance isn't copied in OpenItemWorker.cs */

                ForeignBalance = null, /* currency isn't the same across, hence it being null out */
                ForeignValue = null, /* currency isn't the same across, hence it being null out */
                Currency = null, /* currency isn't the same across, hence it being null out */

                ReferenceText = $"{bills.OpenItems.First().ReferenceText}{Environment.NewLine}{bills.OpenItems.Last().ReferenceText}",
                Regarding = $"{bills.OpenItems.First().Regarding}{Environment.NewLine}{bills.OpenItems.Last().Regarding}",
                StatementRef = $"{bills.OpenItems.First().StatementRef}{Environment.NewLine}{bills.OpenItems.Last().StatementRef}",
                Scope = $"{bills.OpenItems.First().Scope}{Environment.NewLine}{bills.OpenItems.Last().Scope}"
            }, itemModel, "merged");
        }
    }
}