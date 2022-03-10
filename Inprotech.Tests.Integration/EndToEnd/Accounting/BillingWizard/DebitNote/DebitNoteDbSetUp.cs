using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Accounting.Work;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.BillingWizard.DebitNote
{
    public class DebitNoteDbSetUp : DbSetup
    {
        public dynamic ForCaseDebtorDataSetup()
        {
            AccountingDbHelper.SetupPeriod();

            return DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var foreignWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseForeignMultiple.Id, billingData.ServiceCharge1.WipCode, 1000, foreignCurrency: billingData.ForeignCurrency.Id, exchangeRate: (decimal)1.2);

                var foreignWipWithDiscount = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseForeignMultiple.Id, billingData.ServiceCharge1.WipCode, 2000, -200,
                                          foreignCurrency: billingData.ForeignCurrency.Id, exchangeRate: (decimal)1.2);

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
                    LocalValue = foreignWipWithDiscount.Wip.LocalValue + foreignWipWithDiscount.Discount.LocalValue,
                    LocalBalance = foreignWipWithDiscount.Wip.LocalValue.GetValueOrDefault() + foreignWipWithDiscount.Discount.LocalValue.GetValueOrDefault(),
                    ForeignValue = foreignWipWithDiscount.Wip.ForeignValue + foreignWipWithDiscount.Discount.ForeignValue,
                    ForeignBalance = foreignWipWithDiscount.Wip.ForeignValue.GetValueOrDefault() + foreignWipWithDiscount.Discount.ForeignValue.GetValueOrDefault(),
                    Currency = foreignWipWithDiscount.Wip.ForeignCurrency,
                    ExchangeRate = foreignWipWithDiscount.Wip.ExchangeRate
                }.BuildDraftBill(billingData.CaseForeignMultiple.Id, foreignWipWithDiscount.Wip, foreignWipWithDiscount.Discount)
                     .ToArray();

                var discountWipType = x.DbContext.Set<WipType>().Single(_ => _.Id == "DISC");
                var discountWipTemplate = x.DbContext.Set<WipTemplate>().Single(_ => _.WipCode == "DISC");

                return new
                {
                    EntityId = openItems.First().ItemEntityId,
                    TransactionId = openItems.First().ItemTransactionId,
                    RaisedByStaffId = billingData.StaffName.Id,
                    BillSourceCountryCode = billingData.EntityCountry,
                    Case = billingData.CaseForeignMultiple,
                    TotalWip = foreignWipWithDiscount.Wip.LocalValue + foreignWipWithDiscount.Discount.LocalValue + foreignWip.Wip.LocalValue,
                    UnlockedWipAmount = foreignWip.Wip.LocalValue, /* this wasn't included when the draft bill was created */
                    BilledAmount = foreignWipWithDiscount.Wip.LocalValue + foreignWipWithDiscount.Discount.LocalValue,
                    OpenItems = openItems,

                    billingData.ForeignCurrency,

                    UnlockedWip = foreignWip.Wip,
                    LockedWip = foreignWipWithDiscount.Wip,
                    LockedWipDiscount = foreignWipWithDiscount.Discount,

                    ServiceChargeWipTemplate = billingData.ServiceCharge1,
                    ServiceChargeWipType = billingData.ServiceCharge1.WipType,
                    ServiceChargeWipCategory = billingData.ServiceCharge1.WipType.Category,

                    /* this is simplified for test data retrieval, it should be based on effective date, country (or fallback to 'ZZZ') */
                    ServiceChargeTaxRate = x.DbContext.Set<TaxRatesCountry>().Single(_ => _.TaxCode == billingData.ServiceCharge1.TaxCode),

                    DiscountWipTemplate = discountWipTemplate,
                    DiscountWipType = discountWipType,

                    /* this is simplified for test data retrieval, it should be based on effective date, country (or fallback to 'ZZZ') */
                    DiscountTaxRate = x.DbContext.Set<TaxRatesCountry>().Single(_ => _.TaxCode == discountWipTemplate.TaxCode),

                    LockedWipBilledItem = x.DbContext.Set<BilledItem>()
                                           .Single(_ => _.WipEntityId == foreignWipWithDiscount.Wip.EntityId
                                                        && _.WipTransactionId == foreignWipWithDiscount.Wip.TransactionId
                                                        && _.WipSequenceNo == foreignWipWithDiscount.Wip.WipSequenceNo),
                    LockedWipDiscountBilledItem = x.DbContext.Set<BilledItem>()
                                            .Single(_ => _.WipEntityId == foreignWipWithDiscount.Discount.EntityId
                                                        && _.WipTransactionId == foreignWipWithDiscount.Discount.TransactionId
                                                        && _.WipSequenceNo == foreignWipWithDiscount.Discount.WipSequenceNo)
                };
            });
        }
    }
}
