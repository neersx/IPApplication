using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public class OpenItemModel
    {
        public int? ItemEntityId { get; set; }
        public int? ItemTransactionId { get; set; }
        public int? AccountEntityId { get; set; }
        public int AccountDebtorNameId { get; set; }
        public string Action { get; set; }
        public string OpenItemNo { get; set; }
        public DateTime ItemDate { get; set; }
        public DateTime? FinalisedItemDate { get; set; }
        public DateTime? PostDate { get; set; }
        public int? PostPeriodId { get; set; }
        public DateTime? ClosePostDate { get; set; }
        public int? ClosePostPeriodId { get; set; }
        public int Status { get; set; }
        public int ItemType { get; set; }
        public decimal BillPercentage { get; set; }
        public string StaffName { get; set; }
        public int StaffId { get; set; }
        public string StaffProfitCentre { get; set; }
        public string StaffProfitCentreDescription { get; set; }
        public string Currency { get; set; }
        public decimal? ExchangeRate { get; set; }
        public decimal ItemPreTaxValue { get; set; }
        public decimal LocalTaxAmount { get; set; }
        public decimal LocalValue { get; set; }
        public decimal? ForeignTaxAmount { get; set; }
        public decimal? ForeignValue { get; set; }
        public decimal LocalBalance { get; set; }
        public decimal? ForeignBalance { get; set; }
        public decimal? ExchangeRateVariance { get; set; }
        public string StatementRef { get; set; }
        public string ReferenceText { get; set; }
        public int? NameSnapNo { get; set; }
        public short? BillFormatId { get; set; }
        public bool HasBillBeenPrinted { get; set; }
        public string Regarding { get; set; }
        public string Scope { get; set; }
        public int? LanguageId { get; set; }
        public string LanguageDescription { get; set; }
        public string AssociatedOpenItemNo { get; set; }
        public int? ImageId { get; set; }
        public string ForeignEquivalentCurrency { get; set; }
        public decimal? ForeignEquivalentExchangeRate { get; set; }
        public DateTime? ItemDueDate { get; set; }
        public decimal? PenaltyInterest { get; set; }
        public decimal? LocalOriginalTakenUp { get; set; }
        public decimal? ForeignOriginalTakenUp { get; set; }
        public string IncludeOnlyWip { get; set; }
        public string PayForWip { get; set; }
        public string PayPropertyType { get; set; }
        public bool ShouldUseRenewalDebtor { get; set; }
        public bool CanUseRenewalDebtor { get; set; }
        public string CaseProfitCentre { get; set; }
        public int? LockIdentityId { get; set; }

        public decimal BillTotal { get; set; }
        public decimal WriteDown { get; set; }
        public decimal WriteUp { get; set; }
        public int? MainCaseId { get; set; }
        public DateTime? LogDateTimeStamp { get; set; } // TRANSACTIONHEADER.LOGDATETIMESTAMP

        public string LocalCurrencyCode { get; set; }
        public int LocalDecimalPlaces { get; set; }
        public int ForeignDecimalPlaces { get; set; }
        public short? RoundBillValues { get; set; }
        public string CreditReason { get; set; }
        public bool IsWriteDownWip { get; set; }
        public string WriteDownReason { get; set; }
        public DateTime? SelectedWipFromDate { get; set; }
        public DateTime? SelectedWipToDate { get; set; }

        public string ItemTypeDescription { get; set; }

        public string MergedItemKeysInXml { get; set; }
        
        public ICollection<DebtorData> Debtors { get; set; } = new List<DebtorData>();
        
        public ICollection<AvailableWipItem> AvailableWipItems { get; set; } = new List<AvailableWipItem>();

        public ICollection<DebitOrCreditNote> DebitOrCreditNotes { get; set; } = new List<DebitOrCreditNote>();

        public ICollection<BillLine> BillLines { get; set; } = new List<BillLine>();
        
        public ICollection<OpenItemXml> OpenItemXml { get; set; } = new List<OpenItemXml>();

        public ICollection<ModifiedItem> ModifiedItems { get; set; } = new List<ModifiedItem>();

        public string EnteredOpenItemXml { get; set; }
    }

    public static class OpenItemExtensions
    {
        public static bool IsCredit(this OpenItemModel openItemModel)
        {
            return openItemModel.ItemType == (int) ItemType.CreditNote || openItemModel.ItemType == (int) ItemType.InternalCreditNote;
        }
    }
}