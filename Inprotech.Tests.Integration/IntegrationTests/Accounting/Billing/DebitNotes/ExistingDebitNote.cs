using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Billing.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Names;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.DebitNotes
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ExistingDebitNote : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        [Test]
        public void LoadLocalDebtorOpenItems()
        {
            var fixture = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var localWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalMultiple.Id, billingData.ServiceCharge1.WipCode, 1000);

                var localWipWithDiscount = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalMultiple.Id, billingData.ServiceCharge1.WipCode, 2000, -200);

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
                        LocalValue = localWipWithDiscount.Wip.LocalValue + localWipWithDiscount.Discount.LocalValue,
                        LocalBalance = localWipWithDiscount.Wip.LocalValue.GetValueOrDefault() + localWipWithDiscount.Discount.LocalValue.GetValueOrDefault()
                    }.BuildDraftBill(billingData.CaseLocalMultiple.Id, localWipWithDiscount.Wip, localWipWithDiscount.Discount)
                     .ToArray();

                var discountWipType = x.DbContext.Set<WipType>().Single(_ => _.Id == "DISC");
                var discountWipTemplate = x.DbContext.Set<WipTemplate>().Single(_ => _.WipCode == "DISC");

                return new
                {
                    EntityId = openItems.First().ItemEntityId,
                    TransactionId = openItems.First().ItemTransactionId,
                    RaisedByStaffId = billingData.StaffName.Id,
                    BillSourceCountryCode = billingData.EntityCountry,
                    Case = billingData.CaseLocalMultiple,
                    TotalWip = localWipWithDiscount.Wip.LocalValue + localWipWithDiscount.Discount.LocalValue + localWip.Wip.LocalValue,
                    UnlockedWipAmount = localWip.Wip.LocalValue, /* this wasn't included when the draft bill was created */
                    BilledAmount = localWipWithDiscount.Wip.LocalValue + localWipWithDiscount.Discount.LocalValue,
                    OpenItems = openItems,
                    UnlockedWip = localWip.Wip,
                    LockedWip = localWipWithDiscount.Wip,
                    LockedWipDiscount = localWipWithDiscount.Discount,
                    
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
                                           .Single(_ => _.WipEntityId == localWipWithDiscount.Wip.EntityId 
                                                        && _.WipTransactionId == localWipWithDiscount.Wip.TransactionId 
                                                        && _.WipSequenceNo == localWipWithDiscount.Wip.WipSequenceNo),
                    LockedWipDiscountBilledItem = x.DbContext.Set<BilledItem>()
                                            .Single(_ => _.WipEntityId == localWipWithDiscount.Discount.EntityId 
                                                        && _.WipTransactionId == localWipWithDiscount.Discount.TransactionId 
                                                        && _.WipSequenceNo == localWipWithDiscount.Discount.WipSequenceNo)
                };
            });

            foreach (var openItem in fixture.OpenItems)
            {
                /*
                 * The OpenItems here should show individual OpenItemNo, LocalValue, LocalBalance.
                 */
                var itemModel = BillingService.GetOpenItem(fixture.EntityId, openItem.OpenItemNo);

                var expected = new ExpectedOpenItemValues(openItem);

                CommonAssert.OpenItemAreEqual(expected, itemModel);
            }

            var cases = BillingService.GetOpenItemCases(fixture.EntityId, fixture.TransactionId);

            CommonAssert.CaseDataAreEqual(new CaseData
            {
                BillSourceCountryCode = fixture.BillSourceCountryCode,
                CaseId = fixture.Case.Id,
                TotalWip = fixture.TotalWip,
                UnlockedWip = fixture.UnlockedWipAmount,
                IsMainCase = true,
                IsMultiDebtorCase = true
            }, cases.CaseList.Single());

            var debtors = BillingService.GetDebtorList(fixture.EntityId, fixture.TransactionId, fixture.RaisedByStaffId, $"{fixture.Case.Id}");

            CommonAssert.DebtorDataAreEqual(new DebtorData
            {
                NameId = fixture.Case.Debtor1().NameId,
                AddressId = fixture.Case.Debtor1().Name.PostalAddressId,
                BilledAmount = 0,
                BillPercentage = 60,
                OpenItemNo = fixture.OpenItems.First().OpenItemNo,
                TotalWip = fixture.BilledAmount, /* in a standard multi debtor bill, the wip is against the main debtor */
                IsClient = true,
                NameType = KnownNameTypes.Debtor, /* Renewal Debtor is not being used in the test setup */
                References = new List<DebtorReference>
                {
                    new()
                    {
                        CaseId = fixture.Case.Id,
                        DebtorNameId = fixture.Case.Debtor1().NameId,
                        NameType = KnownNameTypes.Debtor
                    }
                }
            }, debtors.DebtorList.First(), "Debtor #1");

            CommonAssert.DebtorDataAreEqual(new DebtorData
            {
                NameId = fixture.Case.Debtor2().NameId,
                AddressId = fixture.Case.Debtor2().Name.PostalAddressId,
                BilledAmount = 0,
                BillPercentage = 40,
                OpenItemNo = fixture.OpenItems.Last().OpenItemNo,
                TotalWip = 0,
                IsClient = true,
                NameType = KnownNameTypes.Debtor /* Renewal Debtor is not being used in the test setup */
            }, debtors.DebtorList.Last(), "Debtor #2");

            var firstBill = fixture.OpenItems.First();
            
            var availableWipItems = BillingService.GetAvailableWip(
                                                                          firstBill.ItemEntityId,
                                                                          firstBill.ItemTransactionId,
                                                                          firstBill.TypeId,
                                                                          firstBill.ItemDate).ToArray();
            
            CommonAssert.AvailableWipIsEqual(new ExpectedWipValues
            {
                Balance = fixture.UnlockedWip.Balance,
                LocalBilled = null, /* this is unlocked so it is null */
                BillItemEntityId = null, /* this is unlocked so it is null */
                BillItemTransactionId = null, /* this is unlocked so it is null */
                BillLineNo = null, /* this is unlocked so it is null */
                CaseId = fixture.UnlockedWip.CaseId,
                CaseRef = fixture.UnlockedWip.Case.Irn,
                WipCode = fixture.UnlockedWip.WipCode,
                
                WipSequenceNo = fixture.UnlockedWip.WipSequenceNo,
                EntityId = fixture.UnlockedWip.EntityId,
                TransactionId = fixture.UnlockedWip.TransactionId,
                TransactionDate = fixture.UnlockedWip.TransactionDate,
                
                NarrativeId = fixture.UnlockedWip.NarrativeId,
                ShortNarrative = fixture.UnlockedWip.ShortNarrative,

                WipTypeId = fixture.ServiceChargeWipTemplate.WipTypeId,
                Description = fixture.ServiceChargeWipTemplate.Description,
                WipCategory = fixture.ServiceChargeWipTemplate.WipType.CategoryId,
                TaxCode = fixture.ServiceChargeWipTemplate.TaxCode,
                TaxRate = fixture.ServiceChargeTaxRate.Rate,
                WipCategorySortOrder = fixture.ServiceChargeWipCategory.CategorySortOrder.GetValueOrDefault(),
                WipTypeSortOrder = fixture.ServiceChargeWipType.WipTypeSortOrder.GetValueOrDefault()
            }, availableWipItems.Single(_ => _.EntityId == fixture.UnlockedWip.EntityId
                                             && _.TransactionId == fixture.UnlockedWip.TransactionId
                                             && _.WipSeqNo == fixture.UnlockedWip.WipSequenceNo), "UnlockedWip");
            
            CommonAssert.AvailableWipIsEqual(new ExpectedWipValues
            {
                Balance = fixture.LockedWip.Balance,
                
                LocalBilled = fixture.LockedWip.LocalValue,
                BillItemEntityId = fixture.LockedWipBilledItem.EntityId,
                BillItemTransactionId = fixture.LockedWipBilledItem.TransactionId,
                BillLineNo = fixture.LockedWipBilledItem.ItemLineNo,

                CaseId = fixture.LockedWip.CaseId,
                CaseRef = fixture.LockedWip.Case.Irn,
                WipCode = fixture.LockedWip.WipCode,
                
                WipSequenceNo = fixture.LockedWip.WipSequenceNo,
                EntityId = fixture.LockedWip.EntityId,
                TransactionId = fixture.LockedWip.TransactionId,
                TransactionDate = fixture.LockedWip.TransactionDate,
                
                NarrativeId = fixture.LockedWip.NarrativeId,
                ShortNarrative = fixture.LockedWip.ShortNarrative,

                WipTypeId = fixture.ServiceChargeWipTemplate.WipTypeId,
                Description = fixture.ServiceChargeWipTemplate.Description,
                WipCategory = fixture.ServiceChargeWipTemplate.WipType.CategoryId,
                TaxCode = fixture.ServiceChargeWipTemplate.TaxCode,
                TaxRate = fixture.ServiceChargeTaxRate.Rate,
                WipCategorySortOrder = fixture.ServiceChargeWipCategory.CategorySortOrder.GetValueOrDefault(),
                WipTypeSortOrder = fixture.ServiceChargeWipType.WipTypeSortOrder.GetValueOrDefault()
            }, availableWipItems.Single(_ => _.EntityId == fixture.LockedWip.EntityId
                                             && _.TransactionId == fixture.LockedWip.TransactionId
                                             && _.WipSeqNo == fixture.LockedWip.WipSequenceNo), "LockedWip");

            CommonAssert.AvailableWipIsEqual(new ExpectedWipValues
            {
                Balance = fixture.LockedWipDiscount.Balance,

                LocalBilled = fixture.LockedWipDiscount.LocalValue,
                BillItemEntityId = fixture.LockedWipDiscountBilledItem.EntityId,
                BillItemTransactionId = fixture.LockedWipDiscountBilledItem.TransactionId,
                BillLineNo = fixture.LockedWipDiscountBilledItem.ItemLineNo,

                CaseId = fixture.LockedWipDiscount.CaseId,
                CaseRef = fixture.LockedWipDiscount.Case.Irn,
                WipCode = fixture.LockedWipDiscount.WipCode,
                
                WipSequenceNo = fixture.LockedWipDiscount.WipSequenceNo,
                EntityId = fixture.LockedWipDiscount.EntityId,
                TransactionId = fixture.LockedWipDiscount.TransactionId,
                TransactionDate = fixture.LockedWipDiscount.TransactionDate,

                NarrativeId = fixture.LockedWipDiscount.NarrativeId,
                ShortNarrative = fixture.LockedWipDiscount.ShortNarrative,

                WipTypeId = fixture.DiscountWipType.Id,
                WipTypeSortOrder = fixture.DiscountWipType.WipTypeSortOrder.GetValueOrDefault(),

                WipCategory = fixture.DiscountWipType.CategoryId,
                WipCategorySortOrder = fixture.ServiceChargeWipCategory.CategorySortOrder.GetValueOrDefault(),
                
                Description = fixture.DiscountWipTemplate.Description,
                TaxCode = fixture.DiscountWipTemplate.TaxCode,
                TaxRate = fixture.DiscountTaxRate.Rate,
                IsDiscount = true

            }, availableWipItems.Single(_ => _.EntityId == fixture.LockedWipDiscount.EntityId
                                             && _.TransactionId == fixture.LockedWipDiscount.TransactionId
                                             && _.WipSeqNo == fixture.LockedWipDiscount.WipSequenceNo), "LockedDiscountWip");
        }

        [Test]
        public void LoadForeignDebtorOpenItems()
        {
            var fixture = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var foreignWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseForeignMultiple.Id, billingData.ServiceCharge1.WipCode, 1000, foreignCurrency: billingData.ForeignCurrency.Id, exchangeRate: (decimal) 1.2);

                var foreignWipWithDiscount = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseForeignMultiple.Id, billingData.ServiceCharge1.WipCode, 2000, -200, 
                                          foreignCurrency: billingData.ForeignCurrency.Id, exchangeRate: (decimal) 1.2);

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

            foreach (var openItem in fixture.OpenItems)
            {
                /*
                 * The OpenItems here should show individual OpenItemNo, LocalValue, LocalBalance.
                 */
                var itemModel = BillingService.GetOpenItem(fixture.EntityId, openItem.OpenItemNo);

                var expected = new ExpectedOpenItemValues(openItem);

                CommonAssert.OpenItemAreEqual(expected, itemModel);
            }

            var cases = BillingService.GetOpenItemCases(fixture.EntityId, fixture.TransactionId);

            CommonAssert.CaseDataAreEqual(new CaseData
            {
                BillSourceCountryCode = fixture.BillSourceCountryCode,
                CaseId = fixture.Case.Id,
                TotalWip = fixture.TotalWip,
                UnlockedWip = fixture.UnlockedWipAmount,
                IsMainCase = true,
                IsMultiDebtorCase = true
            }, cases.CaseList.Single());

            var debtors = BillingService.GetDebtorList(fixture.EntityId, fixture.TransactionId, fixture.RaisedByStaffId, $"{fixture.Case.Id}");

            CommonAssert.DebtorDataAreEqual(new DebtorData
            {
                NameId = fixture.Case.Debtor1().NameId,
                AddressId = fixture.Case.Debtor1().Name.PostalAddressId,
                BilledAmount = 0,
                BillPercentage = 60,
                OpenItemNo = fixture.OpenItems.First().OpenItemNo,
                TotalWip = fixture.BilledAmount, /* in a standard multi debtor bill, the wip is against the main debtor */
                IsClient = true,
                NameType = KnownNameTypes.Debtor, /* Renewal Debtor is not being used in the test setup */
                Currency = fixture.ForeignCurrency.Id,
                BuyExchangeRate = fixture.ForeignCurrency.BuyRate,
                References = new List<DebtorReference>
                {
                    new()
                    {
                        CaseId = fixture.Case.Id,
                        DebtorNameId = fixture.Case.Debtor1().NameId,
                        NameType = KnownNameTypes.Debtor
                    }
                }
            }, debtors.DebtorList.First(), "Debtor #1");

            CommonAssert.DebtorDataAreEqual(new DebtorData
            {
                NameId = fixture.Case.Debtor2().NameId,
                AddressId = fixture.Case.Debtor2().Name.PostalAddressId,
                BilledAmount = 0,
                BillPercentage = 40,
                OpenItemNo = fixture.OpenItems.Last().OpenItemNo,
                TotalWip = 0,
                IsClient = true,
                NameType = KnownNameTypes.Debtor, /* Renewal Debtor is not being used in the test setup */
                Currency = fixture.ForeignCurrency.Id,
                BuyExchangeRate = fixture.ForeignCurrency.BuyRate
            }, debtors.DebtorList.Last(), "Debtor #2");

            var firstBill = fixture.OpenItems.First();
            
            var availableWipItems = BillingService.GetAvailableWip(
                                                                          firstBill.ItemEntityId,
                                                                          firstBill.ItemTransactionId,
                                                                          firstBill.TypeId,
                                                                          firstBill.ItemDate).ToArray();
            
            CommonAssert.AvailableWipIsEqual(new ExpectedWipValues
            {
                Balance = fixture.UnlockedWip.Balance,
                ForeignBalance = fixture.UnlockedWip.ForeignBalance,
                ForeignCurrency = fixture.UnlockedWip.ForeignCurrency,
                LocalBilled = null, /* this is unlocked so it is null */
                BillItemEntityId = null, /* this is unlocked so it is null */
                BillItemTransactionId = null, /* this is unlocked so it is null */
                BillLineNo = null, /* this is unlocked so it is null */
                CaseId = fixture.UnlockedWip.CaseId,
                CaseRef = fixture.UnlockedWip.Case.Irn,
                WipCode = fixture.UnlockedWip.WipCode,
                
                WipSequenceNo = fixture.UnlockedWip.WipSequenceNo,
                EntityId = fixture.UnlockedWip.EntityId,
                TransactionId = fixture.UnlockedWip.TransactionId,
                TransactionDate = fixture.UnlockedWip.TransactionDate,
                
                NarrativeId = fixture.UnlockedWip.NarrativeId,
                ShortNarrative = fixture.UnlockedWip.ShortNarrative,

                WipTypeId = fixture.ServiceChargeWipTemplate.WipTypeId,
                Description = fixture.ServiceChargeWipTemplate.Description,
                WipCategory = fixture.ServiceChargeWipTemplate.WipType.CategoryId,
                TaxCode = fixture.ServiceChargeWipTemplate.TaxCode,
                TaxRate = fixture.ServiceChargeTaxRate.Rate,
                WipCategorySortOrder = fixture.ServiceChargeWipCategory.CategorySortOrder.GetValueOrDefault(),
                WipTypeSortOrder = fixture.ServiceChargeWipType.WipTypeSortOrder.GetValueOrDefault()
            }, availableWipItems.Single(_ => _.EntityId == fixture.UnlockedWip.EntityId
                                             && _.TransactionId == fixture.UnlockedWip.TransactionId
                                             && _.WipSeqNo == fixture.UnlockedWip.WipSequenceNo), "UnlockedWip");
            
            CommonAssert.AvailableWipIsEqual(new ExpectedWipValues
            {
                Balance = fixture.LockedWip.Balance,
                ForeignBalance = fixture.LockedWip.ForeignBalance,
                ForeignCurrency = fixture.LockedWip.ForeignCurrency,

                LocalBilled = fixture.LockedWip.LocalValue,
                ForeignBilled = fixture.LockedWip.ForeignValue,
                BillItemEntityId = fixture.LockedWipBilledItem.EntityId,
                BillItemTransactionId = fixture.LockedWipBilledItem.TransactionId,
                BillLineNo = fixture.LockedWipBilledItem.ItemLineNo,

                CaseId = fixture.LockedWip.CaseId,
                CaseRef = fixture.LockedWip.Case.Irn,
                WipCode = fixture.LockedWip.WipCode,
                
                WipSequenceNo = fixture.LockedWip.WipSequenceNo,
                EntityId = fixture.LockedWip.EntityId,
                TransactionId = fixture.LockedWip.TransactionId,
                TransactionDate = fixture.LockedWip.TransactionDate,
                
                NarrativeId = fixture.LockedWip.NarrativeId,
                ShortNarrative = fixture.LockedWip.ShortNarrative,

                WipTypeId = fixture.ServiceChargeWipTemplate.WipTypeId,
                Description = fixture.ServiceChargeWipTemplate.Description,
                WipCategory = fixture.ServiceChargeWipTemplate.WipType.CategoryId,
                TaxCode = fixture.ServiceChargeWipTemplate.TaxCode,
                TaxRate = fixture.ServiceChargeTaxRate.Rate,
                WipCategorySortOrder = fixture.ServiceChargeWipCategory.CategorySortOrder.GetValueOrDefault(),
                WipTypeSortOrder = fixture.ServiceChargeWipType.WipTypeSortOrder.GetValueOrDefault()
            }, availableWipItems.Single(_ => _.EntityId == fixture.LockedWip.EntityId
                                             && _.TransactionId == fixture.LockedWip.TransactionId
                                             && _.WipSeqNo == fixture.LockedWip.WipSequenceNo), "LockedWip");

            CommonAssert.AvailableWipIsEqual(new ExpectedWipValues
            {
                Balance = fixture.LockedWipDiscount.Balance,
                ForeignBalance = fixture.LockedWipDiscount.ForeignBalance,
                ForeignCurrency = fixture.LockedWipDiscount.ForeignCurrency,

                LocalBilled = fixture.LockedWipDiscount.LocalValue,
                ForeignBilled = fixture.LockedWipDiscount.ForeignValue,
                BillItemEntityId = fixture.LockedWipDiscountBilledItem.EntityId,
                BillItemTransactionId = fixture.LockedWipDiscountBilledItem.TransactionId,
                BillLineNo = fixture.LockedWipDiscountBilledItem.ItemLineNo,

                CaseId = fixture.LockedWipDiscount.CaseId,
                CaseRef = fixture.LockedWipDiscount.Case.Irn,
                WipCode = fixture.LockedWipDiscount.WipCode,
                
                WipSequenceNo = fixture.LockedWipDiscount.WipSequenceNo,
                EntityId = fixture.LockedWipDiscount.EntityId,
                TransactionId = fixture.LockedWipDiscount.TransactionId,
                TransactionDate = fixture.LockedWipDiscount.TransactionDate,

                NarrativeId = fixture.LockedWipDiscount.NarrativeId,
                ShortNarrative = fixture.LockedWipDiscount.ShortNarrative,

                WipTypeId = fixture.DiscountWipType.Id,
                WipTypeSortOrder = fixture.DiscountWipType.WipTypeSortOrder.GetValueOrDefault(),

                WipCategory = fixture.DiscountWipType.CategoryId,
                WipCategorySortOrder = fixture.ServiceChargeWipCategory.CategorySortOrder.GetValueOrDefault(),
                
                Description = fixture.DiscountWipTemplate.Description,
                TaxCode = fixture.DiscountWipTemplate.TaxCode,
                TaxRate = fixture.DiscountTaxRate.Rate,
                IsDiscount = true

            }, availableWipItems.Single(_ => _.EntityId == fixture.LockedWipDiscount.EntityId
                                             && _.TransactionId == fixture.LockedWipDiscount.TransactionId
                                             && _.WipSeqNo == fixture.LockedWipDiscount.WipSequenceNo), "LockedDiscountWip");
        }

        [Test]
        public void LoadDebtorsWithOverridenCopiesTo()
        {
            var data = DbSetup.Do(x =>
            {
                const decimal wipAmount = 1000;

                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var caseId = billingData.CaseLocalSingle.Id;

                var localWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, caseId, billingData.ServiceCharge1.WipCode, wipAmount);

                var openItem = new OpenItemBuilder(x.DbContext)
                               {
                                   StaffId = billingData.StaffName.Id,
                                   StaffProfitCentre = billingData.StaffProfitCentre.Id,
                                   EntityId = billingData.EntityId,
                                   LocalValue = localWip.Wip.LocalValue,
                                   LocalBalance = localWip.Wip.Balance.GetValueOrDefault()
                               }
                               .BuildDraftBill(caseId, localWip.Wip)
                               .Single();

                var copiesTo = new NameBuilder(x.DbContext).CreateClientOrg("cc-org");
                var copiesToContact = new NameBuilder(x.DbContext).CreateClientIndividual("cc-contact");

                /*
                 * All names included in a bill has Name Address Snapshot for auditing purposes
                 */
                var snapshot = x.InsertWithNewId(new NameAddressSnapshot
                {
                    NameId = copiesTo.Id,
                    FormattedName = copiesTo.Formatted(),
                    FormattedAddress = copiesTo.PostalAddress().FormattedOrNull(),
                    AttentionNameId = copiesToContact.Id,
                    AddressCode = copiesTo.PostalAddressId
                }, _ => _.NameSnapshotId);

                /*
                 * When copy to has been amended,
                 * i.e. no longer derived from case relationship or name relationship, it is held in OPENITEMCOPYTO
                 * When it is held in the OPENITEMCOPYTO, it pulls data from name address snapshot.
                 */
                x.Insert(new OpenItemCopyTo
                {
                    ItemEntityId = openItem.ItemEntityId,
                    ItemTransactionId = openItem.ItemTransactionId,
                    AccountEntityId = openItem.AccountEntityId,
                    AccountDebtorId = billingData.CaseLocalSingle.Debtor1().NameId,
                    NameSnapshotId = snapshot.NameSnapshotId
                });

                return new
                {
                    CaseId = caseId,
                    DebtorId = billingData.CaseLocalSingle.Debtor1().NameId,
                    DebtorAddressId = billingData.CaseLocalSingle.Debtor1().Name.PostalAddressId,
                    RaisedByStaffId = billingData.StaffName.Id,
                    TotalWip = wipAmount,
                    NameSnapshot = snapshot,
                    OpenItem = openItem
                };
            });

            var debtors = BillingService.GetDebtorList(data.OpenItem.ItemEntityId, data.OpenItem.ItemTransactionId, data.RaisedByStaffId, $"{data.CaseId}");

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId,
                                                AddressId = data.DebtorAddressId,
                                                OpenItemNo = data.OpenItem.OpenItemNo,
                                                TotalWip = data.TotalWip,
                                                NameType = KnownNameTypes.Debtor,
                                                BillPercentage = 100,
                                                BilledAmount = 0,
                                                IsMultiCaseAllowed = false,
                                                CopiesTos = new List<DebtorCopiesTo>
                                                {
                                                    new()
                                                    {
                                                        DebtorNameId = data.DebtorId,
                                                        Address = data.NameSnapshot.FormattedAddress,
                                                        AddressId = data.NameSnapshot.AddressCode,
                                                        ContactNameId = data.NameSnapshot.AttentionNameId,
                                                        ContactName = data.NameSnapshot.FormattedAttention,
                                                        CopyToName = data.NameSnapshot.FormattedName,
                                                        CopyToNameId = data.NameSnapshot.NameId.GetValueOrDefault()
                                                    }
                                                },
                                                References = new List<DebtorReference>
                                                {
                                                    new()
                                                    {
                                                        CaseId = data.CaseId,
                                                        DebtorNameId = data.DebtorId,
                                                        NameType = KnownNameTypes.Debtor
                                                    }
                                                }
                                            },
                                            debtors.DebtorList.Single());
        }
    }
}