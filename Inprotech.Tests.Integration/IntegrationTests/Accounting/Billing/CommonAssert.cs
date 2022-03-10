using System;
using System.Linq;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.References;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing
{
    public class ExpectedOpenItemValues
    {
        public ExpectedOpenItemValues()
        {

        }

        public ExpectedOpenItemValues(OpenItem openItem)
        {
            Id = openItem.Id;
            ItemEntityId = openItem.ItemEntityId;
            ItemTransactionId = openItem.ItemTransactionId;
            AccountEntityId = openItem.AccountEntityId;
            AccountDebtorNameId = openItem.AccountDebtorId;
            OpenItemNo = openItem.OpenItemNo;
            LocalBalance = openItem.LocalBalance;
            LocalValue = openItem.LocalValue;
            Currency = openItem.Currency;
            ExchangeRate = openItem.ExchangeRate;
            ExchangeRateVariance = openItem.ExchangeRateVariance;
            ForeignValue = openItem.ForeignValue;
            ForeignBalance = openItem.ForeignBalance;
            Status = openItem.Status;
            StaffProfitCentre = openItem.StaffProfitCentre;
            CaseProfitCentre = openItem.CaseProfitCentre;
            ItemDate = openItem.ItemDate;
            TypeId = openItem.TypeId;
            PreTaxValue = openItem.PreTaxValue;
            LocalTaxAmount = openItem.LocalTaxAmount;
            ForeignTaxAmount = openItem.ForeignTaxAmount;
            BillPercentage = openItem.BillPercentage;
            StatementRef = openItem.StatementRef;
            ReferenceText = openItem.ReferenceText;
            Regarding = openItem.Regarding;
            Scope = openItem.Scope;
            MainCaseId = openItem.MainCaseId;
        }

        public int? Id { get; protected set; }
        public int? ItemEntityId { get; set; }
        public int? ItemTransactionId { get; set; }
        public int? AccountEntityId { get; set; }
        public int? AccountDebtorNameId { get; set; }
        public string OpenItemNo { get; set; }
        public decimal? LocalBalance { get; set; }
        public decimal? LocalValue { get; set; }
        public string Currency { get; set; }
        public decimal? ExchangeRate { get; set; }
        public decimal? ExchangeRateVariance { get; set; }
        public decimal? ForeignValue { get; set; }
        public decimal? ForeignBalance { get; set; }
        public TransactionStatus Status { get; set; }
        public int? StaffId { get; set; }
        public string StaffProfitCentre { get; set; }
        public string CaseProfitCentre { get; set; }
        public DateTime? ItemDate { get; set; }
        public ItemType TypeId { get; set; }
        public decimal? PreTaxValue { get; set; }
        public decimal? LocalTaxAmount { get; set; }
        public decimal? ForeignTaxAmount { get; set; }
        public decimal? BillPercentage { get; set; }
        public string StatementRef { get; set; }
        public string ReferenceText { get; set; }
        public string Regarding { get; set; }
        public string Scope { get; set; }
        public int? MainCaseId { get; set; }
    }

    class ExpectedWipValues
    {
        public decimal? Balance { get; set; }
        public int? CaseId { get; set; }
        public string Description { get; set; }
        public int? EntityId { get; set; }
        public int? TransactionId { get; set; }
        public DateTime? TransactionDate { get; set; }
        public decimal? ForeignBalance { get; set; }
        public string CaseRef { get; set; }
        public string ForeignCurrency { get; set; }
        public string TaxCode { get; set; }
        public decimal? TaxRate { get; set; }
        public string WipCategory { get; set; }
        public int? WipCategorySortOrder { get; set; }
        public string WipCode { get; set; }
        public string WipTypeId { get; set; }
        public int? WipTypeSortOrder { get; set; }

        public int? BillItemEntityId { get; set; }
        public int? BillItemTransactionId { get; set; }
        public int? BillLineNo { get; set; }
        public bool IsDiscount { get; set; }

        public bool IsMargin { get; set; }
        public decimal? LocalBilled { get; set; }
        public decimal? ForeignBilled { get; set; }
        public short? WipSequenceNo { get; set; }
        public int? NarrativeId { get; set; }
        public string ShortNarrative { get; set; }
        public int? AccountClientId { get; set; }
    }
    
    public class CommonAssert
    {
        internal static void OpenItemAreEqual(ExpectedOpenItemValues openItemValues, OpenItemModel itemModel, string prefix = null)
        {
            Assert.AreEqual(openItemValues.ItemEntityId, itemModel.ItemEntityId, $"{prefix ?? openItemValues.OpenItemNo} - ItemEntityId");
            Assert.AreEqual(openItemValues.OpenItemNo, itemModel.OpenItemNo, $"{prefix ?? openItemValues.OpenItemNo} - OpenItemNo");
            Assert.AreEqual(openItemValues.AccountDebtorNameId, itemModel.AccountDebtorNameId, $"{prefix ?? openItemValues.OpenItemNo} - AccountDebtorNameId");
            Assert.AreEqual(openItemValues.AccountEntityId, itemModel.AccountEntityId, $"{prefix ?? openItemValues.OpenItemNo} - AccountEntityId");
            Assert.AreEqual(openItemValues.BillPercentage, itemModel.BillPercentage, $"{prefix ?? openItemValues.OpenItemNo} - BillPercentage");
            Assert.AreEqual(openItemValues.StaffProfitCentre, itemModel.StaffProfitCentre, $"{prefix ?? openItemValues.OpenItemNo} - StaffProfitCentre");
            Assert.AreEqual(openItemValues.ItemDate, itemModel.ItemDate, $"{prefix ?? openItemValues.OpenItemNo} - ItemDate");
            Assert.AreEqual(openItemValues.ItemTransactionId, itemModel.ItemTransactionId, $"{prefix ?? openItemValues.OpenItemNo} - ItemTransactionId");
            Assert.AreEqual((int) openItemValues.TypeId, itemModel.ItemType, $"{prefix ?? openItemValues.OpenItemNo} - ItemType");
            Assert.AreEqual((int) openItemValues.Status, itemModel.Status, $"{prefix ?? openItemValues.OpenItemNo} - ItemStatus");

            Assert.AreEqual(openItemValues.LocalBalance, itemModel.LocalBalance, $"{prefix ?? openItemValues.OpenItemNo} - LocalBalance");
            Assert.AreEqual(openItemValues.LocalValue, itemModel.LocalValue, $"{prefix ?? openItemValues.OpenItemNo} - LocalValue");

            Assert.AreEqual(openItemValues.ForeignBalance, itemModel.ForeignBalance, $"{prefix ?? openItemValues.OpenItemNo} - ForeignBalance");
            Assert.AreEqual(openItemValues.ForeignValue, itemModel.ForeignValue, $"{prefix ?? openItemValues.OpenItemNo} - ForeignValue");
            Assert.AreEqual(openItemValues.ExchangeRate, itemModel.ExchangeRate, $"{prefix ?? openItemValues.OpenItemNo} - ExchangeRate");
            Assert.AreEqual(openItemValues.ExchangeRateVariance, itemModel.ExchangeRateVariance, $"{prefix ?? openItemValues.OpenItemNo} - ExchangeRateVariance");
            Assert.AreEqual(openItemValues.Currency, itemModel.Currency, $"{prefix ?? openItemValues.OpenItemNo} - Currency");

            Assert.AreEqual(openItemValues.ReferenceText, itemModel.ReferenceText, $"{prefix ?? openItemValues.OpenItemNo} - ReferenceText");
            Assert.AreEqual(openItemValues.Regarding, itemModel.Regarding, $"{prefix ?? openItemValues.OpenItemNo} - Regarding");
            Assert.AreEqual(openItemValues.StatementRef, itemModel.StatementRef, $"{prefix ?? openItemValues.OpenItemNo} - StatementRef");
            Assert.AreEqual(openItemValues.Scope, itemModel.Scope, $"{prefix ?? openItemValues.OpenItemNo} - Scope");
        }

        internal static void CaseDataAreEqual(CaseData expected, CaseData actual, string prefix = null)
        {
            var effectivePrefix = prefix;
            if (string.IsNullOrWhiteSpace(prefix))
            {
                effectivePrefix = $"{expected.CaseReference} ({expected.CaseId})";
            }

            Assert.AreEqual(expected.CaseId, actual.CaseId, $"{effectivePrefix} - {nameof(expected.CaseId)}");
            Assert.AreEqual(expected.TotalCredits, actual.TotalCredits, $"{effectivePrefix} - {nameof(expected.TotalCredits)}");
            Assert.AreEqual(expected.UnlockedWip, actual.UnlockedWip, $"{effectivePrefix} - {nameof(expected.UnlockedWip)}");
            Assert.AreEqual(expected.TotalWip, actual.TotalWip, $"{effectivePrefix} - {nameof(expected.TotalWip)}");
            Assert.AreEqual(expected.OpenAction, actual.OpenAction, $"{effectivePrefix} - {nameof(expected.OpenAction)}");
            Assert.AreEqual(expected.IsMainCase, actual.IsMainCase, $"{effectivePrefix} - {nameof(expected.IsMainCase)}");
            Assert.AreEqual(expected.LanguageId, actual.LanguageId, $"{effectivePrefix} - {nameof(expected.LanguageId)}");
            Assert.AreEqual(expected.BillSourceCountryCode, actual.BillSourceCountryCode, $"{effectivePrefix} - {nameof(expected.BillSourceCountryCode)}");
            Assert.AreEqual(expected.CaseListId, actual.CaseListId, $"{effectivePrefix} - {nameof(expected.CaseListId)}");
            Assert.AreEqual(expected.TaxCode, actual.TaxCode, $"{effectivePrefix} - {nameof(expected.TaxCode)}");
            Assert.AreEqual(expected.TaxRate, actual.TaxRate, $"{effectivePrefix} - {nameof(expected.TaxRate)}");
            Assert.AreEqual(expected.CaseProfitCentre, actual.CaseProfitCentre, $"{effectivePrefix} - {nameof(expected.CaseProfitCentre)}");
            Assert.AreEqual(expected.IsMultiDebtorCase, actual.IsMultiDebtorCase, $"{effectivePrefix} - {nameof(expected.IsMultiDebtorCase)}");
            Assert.AreEqual(expected.CaseStatus, actual.CaseStatus, $"{effectivePrefix} - {nameof(expected.CaseStatus)}");
            Assert.AreEqual(expected.OfficialNumber, actual.OfficialNumber, $"{effectivePrefix} - {nameof(expected.OfficialNumber)}");
            Assert.AreEqual(expected.HasRestrictedStatusForBilling, actual.HasRestrictedStatusForBilling, $"{effectivePrefix} - {nameof(expected.HasRestrictedStatusForBilling)}");
            Assert.AreEqual(expected.OfficeEntityId, actual.OfficeEntityId, $"{effectivePrefix} - {nameof(expected.OfficeEntityId)}");
            CollectionAssert.AreEqual(expected.DraftBills, actual.DraftBills, $"{effectivePrefix} - {nameof(expected.DraftBills)}");

            for (var i = 0; i< expected.UnpostedTimeList.Count; i++)
            {
                var expectedUnpostedTime = expected.UnpostedTimeList.ElementAt(i);
                var actualUnpostedTime = actual.UnpostedTimeList.ElementAt(i);
                
                Assert.AreEqual(expectedUnpostedTime.NameId, actualUnpostedTime.NameId, $"{effectivePrefix} Unposted Time #{expectedUnpostedTime.NameId}- {nameof(expectedUnpostedTime.NameId)}");
                Assert.AreEqual(expectedUnpostedTime.Name, actualUnpostedTime.Name, $"{effectivePrefix} Unposted Time #{expectedUnpostedTime.Name}- {nameof(expectedUnpostedTime.Name)}");
                Assert.AreEqual(expectedUnpostedTime.StartTime, actualUnpostedTime.StartTime, $"{effectivePrefix} Unposted Time #{expectedUnpostedTime.StartTime}- {nameof(expectedUnpostedTime.StartTime)}");
                Assert.AreEqual(expectedUnpostedTime.TimeValue, actualUnpostedTime.TimeValue, $"{effectivePrefix} Unposted Time #{expectedUnpostedTime.TimeValue}- {nameof(expectedUnpostedTime.TimeValue)}");
                Assert.AreEqual(expectedUnpostedTime.TotalTime, actualUnpostedTime.TotalTime, $"{effectivePrefix} Unposted Time #{expectedUnpostedTime.TotalTime}- {nameof(expectedUnpostedTime.TotalTime)}");
            }
        }

        internal static void DebtorDataAreEqual(DebtorData expected, DebtorData actual, string prefix = null)
        {
            var effectivePrefix = prefix;
            if (string.IsNullOrWhiteSpace(prefix))
            {
                effectivePrefix = $"{expected.FormattedNameWithCode} ({expected.NameId})";
            }

            Assert.AreEqual(expected.AddressId, actual.AddressId, $"{effectivePrefix} - {nameof(expected.AddressId)}");
            Assert.AreEqual(expected.IsMultiCaseAllowed, actual.IsMultiCaseAllowed, $"{effectivePrefix} - {nameof(expected.IsMultiCaseAllowed)}");
            Assert.AreEqual(expected.BilledAmount, actual.BilledAmount, $"{effectivePrefix} - {nameof(expected.BilledAmount)}");
            Assert.AreEqual(expected.BillFormatProfileId, actual.BillFormatProfileId, $"{effectivePrefix} - {nameof(expected.BillFormatProfileId)}");
            Assert.AreEqual(expected.BillingCap, actual.BillingCap, $"{effectivePrefix} - {nameof(expected.BillingCap)}");
            Assert.AreEqual(expected.BillingCapStart, actual.BillingCapStart, $"{effectivePrefix} - {nameof(expected.BillingCapStart)}");
            Assert.AreEqual(expected.BillingCapEnd, actual.BillingCapEnd, $"{effectivePrefix} - {nameof(expected.BillingCapEnd)}");
            Assert.AreEqual(expected.BillMapProfileId, actual.BillMapProfileId, $"{effectivePrefix} - {nameof(expected.BillMapProfileId)}");
            Assert.AreEqual(expected.BillPercentage, actual.BillPercentage, $"{effectivePrefix} - {nameof(expected.BillPercentage)}");
            Assert.AreEqual(expected.BillToNameId, actual.BillToNameId, $"{effectivePrefix} - {nameof(expected.BillToNameId)}");
            Assert.AreEqual(expected.BuyExchangeRate, actual.BuyExchangeRate, $"{effectivePrefix} - {nameof(expected.BuyExchangeRate)}");
            Assert.AreEqual(expected.CaseId, actual.CaseId, $"{effectivePrefix} - {nameof(expected.CaseId)}");
            Assert.AreEqual(expected.Currency, actual.Currency, $"{effectivePrefix} - {nameof(expected.Currency)}");
            Assert.AreEqual(expected.OpenItemNo, actual.OpenItemNo, $"{effectivePrefix} - {nameof(expected.OpenItemNo)}");
            Assert.AreEqual(expected.ReferenceNo, actual.ReferenceNo, $"{effectivePrefix} - {nameof(expected.ReferenceNo)}");
            Assert.AreEqual(expected.TaxCode, actual.TaxCode, $"{effectivePrefix} - {nameof(expected.TaxCode)}");
            Assert.AreEqual(expected.TaxRate, actual.TaxRate, $"{effectivePrefix} - {nameof(expected.TaxRate)}");
            Assert.AreEqual(expected.OfficeEntityId, actual.OfficeEntityId, $"{effectivePrefix} - {nameof(expected.OfficeEntityId)}");
            Assert.AreEqual(expected.TotalCredits, actual.TotalCredits, $"{effectivePrefix} - {nameof(expected.TotalCredits)}");
            Assert.AreEqual(expected.UseSendBillsTo, actual.UseSendBillsTo, $"{effectivePrefix} - {nameof(expected.UseSendBillsTo)}");
            Assert.AreEqual(expected.TotalWip, actual.TotalWip, $"{effectivePrefix} - {nameof(expected.TotalWip)}");
            Assert.AreEqual(expected.ErrorMessage, actual.ErrorMessage, $"{effectivePrefix} - {nameof(expected.ErrorMessage)}");
            Assert.AreEqual(expected.NameType, actual.NameType, $"{effectivePrefix} - {nameof(expected.NameType)}");
            Assert.AreEqual(expected.NameId, actual.NameId, $"{effectivePrefix} - {nameof(expected.NameId)}");

            foreach (var expectedDiscount in expected.Discounts)
            {
                var actualDiscount = actual.Discounts.Single(_ => _.Sequence == expectedDiscount.Sequence);
                
                Assert.AreEqual(expectedDiscount.NameId, actualDiscount.NameId, $"{effectivePrefix} Discount #{expectedDiscount.NameId}- {nameof(expectedDiscount.NameId)}");
                Assert.AreEqual(expectedDiscount.BasedOnAmount, actualDiscount.BasedOnAmount, $"{effectivePrefix} Discount #{expectedDiscount.BasedOnAmount}- {nameof(expectedDiscount.BasedOnAmount)}");
                Assert.AreEqual(expectedDiscount.DiscountRate, actualDiscount.DiscountRate, $"{effectivePrefix} Discount #{expectedDiscount.DiscountRate}- {nameof(expectedDiscount.DiscountRate)}");
            }

            foreach (var expectedWarning in expected.Warnings)
            {
                var actualWarning = actual.Warnings.Single(_ => _.NameId == expectedWarning.NameId);

                Assert.AreEqual(expectedWarning.NameId, actualWarning.NameId, $"{effectivePrefix} Warning #{expectedWarning.NameId}- {nameof(expectedWarning.NameId)}");
                Assert.AreEqual(expectedWarning.WarningError, actualWarning.WarningError, $"{effectivePrefix} Warning #{expectedWarning.WarningError}- {nameof(expectedWarning.WarningError)}");
            }

            foreach (var expectedCopiesTo in expected.CopiesTos)
            {
                var actualCopiesTo = actual.CopiesTos.Single(_ => _.DebtorNameId == expectedCopiesTo.DebtorNameId);

                Assert.AreEqual(expectedCopiesTo.DebtorNameId, actualCopiesTo.DebtorNameId, $"{effectivePrefix} Copies To #{expectedCopiesTo.DebtorNameId}- {nameof(expectedCopiesTo.DebtorNameId)}");
                Assert.AreEqual(expectedCopiesTo.ContactName, actualCopiesTo.ContactName, $"{effectivePrefix} Copies To #{expectedCopiesTo.ContactName}- {nameof(expectedCopiesTo.ContactName)}");
                Assert.AreEqual(expectedCopiesTo.ContactNameId, actualCopiesTo.ContactNameId, $"{effectivePrefix} Copies To #{expectedCopiesTo.ContactNameId}- {nameof(expectedCopiesTo.ContactNameId)}");
                Assert.AreEqual(expectedCopiesTo.CopyToNameId, actualCopiesTo.CopyToNameId, $"{effectivePrefix} Copies To #{expectedCopiesTo.CopyToNameId}- {nameof(expectedCopiesTo.CopyToNameId)}");
                Assert.AreEqual(expectedCopiesTo.AddressId, actualCopiesTo.AddressId, $"{effectivePrefix} Copies To #{expectedCopiesTo.AddressId}- {nameof(expectedCopiesTo.AddressId)}");
            }

            foreach (var expectedReference in expected.References)
            {
                var actualReference = actual.References.Single(_ => _.DebtorNameId == expectedReference.DebtorNameId);

                Assert.AreEqual(expectedReference.DebtorNameId, actualReference.DebtorNameId, $"{effectivePrefix} Debtor Ref #{expectedReference.DebtorNameId}- {nameof(expectedReference.DebtorNameId)}");
                Assert.AreEqual(expectedReference.CaseId, actualReference.CaseId, $"{effectivePrefix} Debtor Ref #{expectedReference.CaseId}- {nameof(expectedReference.CaseId)}");
                Assert.AreEqual(expectedReference.NameType, actualReference.NameType, $"{effectivePrefix} Debtor Ref #{expectedReference.NameType}- {nameof(expectedReference.NameType)}");
                Assert.AreEqual(expectedReference.ReferenceNo, actualReference.ReferenceNo, $"{effectivePrefix} Debtor Ref #{expectedReference.ReferenceNo}- {nameof(expectedReference.ReferenceNo)}");
            }
        }

        internal static void BillRuleIsEqual(BillSettings expected, BillSettings actual, string suffix)
        {
            Assert.AreEqual(expected.DefaultEntityId, actual.DefaultEntityId, $"{nameof(actual.DefaultEntityId)} - {suffix}");
            Assert.AreEqual(expected.MinimumWipReasonCode, actual.MinimumWipReasonCode, $"{nameof(actual.MinimumWipReasonCode)} - {suffix}");
            Assert.AreEqual(expected.MinimumNetBill, actual.MinimumNetBill, $"{nameof(actual.MinimumNetBill)} - {suffix}");
            CollectionAssert.AreEqual(expected.MinimumWipValues, actual.MinimumWipValues, $"{nameof(actual.MinimumWipValues)} - {suffix}");
        }

        internal static void BillReferenceIsEqual(BillReference expected, BillReference actual, string suffix)
        {
            Assert.AreEqual(expected.BillScope, actual.BillScope, $"{suffix} - {nameof(actual.BillScope)} should be equal");
            Assert.AreEqual(expected.ReferenceText, actual.ReferenceText, $"{suffix} - {nameof(actual.ReferenceText)} should be equal");
            Assert.AreEqual(expected.StatementText, actual.StatementText, $"{suffix} - {nameof(actual.StatementText)} should be equal");
            Assert.AreEqual(expected.Regarding, actual.Regarding, $"{suffix} - {nameof(actual.Regarding)} should be equal");
        }

        internal static void AvailableWipIsEqual(ExpectedWipValues expected, AvailableWipItem actual, string suffix)
        {
            Assert.AreEqual(expected.Balance, actual.Balance, $"{nameof(actual.Balance)} - {suffix}");
            Assert.AreEqual(expected.ForeignBalance, actual.ForeignBalance, $"{nameof(actual.ForeignBalance)} - {suffix}");
            Assert.AreEqual(expected.LocalBilled, actual.LocalBilled, $"{nameof(actual.LocalBilled)} - {suffix}");
            Assert.AreEqual(expected.ForeignBilled, actual.ForeignBilled, $"{nameof(actual.ForeignBilled)} - {suffix}");
            Assert.AreEqual(expected.CaseId, actual.CaseId, $"{nameof(actual.CaseId)} - {suffix}");
            Assert.AreEqual(expected.CaseRef, actual.CaseRef, $"{nameof(actual.CaseRef)} - {suffix}");
            Assert.AreEqual(expected.Description, actual.Description, $"{nameof(actual.Description)} - {suffix}");
            Assert.AreEqual(expected.WipCode, actual.WipCode, $"{nameof(actual.WipCode)} - {suffix}");
            Assert.AreEqual(expected.WipCategory, actual.WipCategory, $"{nameof(actual.WipCategory)} - {suffix}");
            Assert.AreEqual(expected.WipTypeId, actual.WipTypeId, $"{nameof(actual.WipTypeId)} - {suffix}");
            Assert.AreEqual(expected.WipCategorySortOrder, actual.WipCategorySortOrder, $"{nameof(actual.WipCategorySortOrder)} - {suffix}");
            Assert.AreEqual(expected.WipTypeSortOrder, actual.WipTypeSortOrder, $"{nameof(actual.WipTypeSortOrder)} - {suffix}");
            Assert.AreEqual(expected.WipSequenceNo, actual.WipSeqNo, $"{nameof(actual.WipSeqNo)} - {suffix}");
            Assert.AreEqual(expected.EntityId, actual.EntityId, $"{nameof(actual.EntityId)} - {suffix}");
            Assert.AreEqual(expected.TransactionId, actual.TransactionId, $"{nameof(actual.TransactionId)} - {suffix}");
            Assert.AreEqual(expected.TransactionDate, actual.TransactionDate, $"{nameof(actual.TransactionDate)} - {suffix}");
            Assert.AreEqual(expected.ForeignCurrency, actual.ForeignCurrency, $"{nameof(actual.ForeignCurrency)} - {suffix}");
            Assert.AreEqual(expected.NarrativeId, actual.NarrativeId, $"{nameof(actual.NarrativeId)} - {suffix}");
            Assert.AreEqual(expected.ShortNarrative, actual.ShortNarrative, $"{nameof(actual.ShortNarrative)} - {suffix}");
            Assert.AreEqual(expected.TaxCode, actual.TaxCode, $"{nameof(actual.TaxCode)} - {suffix}");
            Assert.AreEqual(expected.TaxRate, actual.TaxRate, $"{nameof(actual.TaxRate)} - {suffix}");
            Assert.AreEqual(expected.BillItemEntityId, actual.BillItemEntityId, $"{nameof(actual.BillItemEntityId)} - {suffix}");
            Assert.AreEqual(expected.BillItemTransactionId, actual.BillItemTransactionId, $"{nameof(actual.BillItemTransactionId)} - {suffix}");
            Assert.AreEqual(expected.BillLineNo, actual.BillLineNo, $"{nameof(actual.BillLineNo)} - {suffix}");
            Assert.AreEqual(expected.IsDiscount, actual.IsDiscount, $"{nameof(actual.IsDiscount)} - {suffix}");
            Assert.AreEqual(expected.IsMargin, actual.IsMargin, $"{nameof(actual.IsMargin)} - {suffix}");
        }
    }
}