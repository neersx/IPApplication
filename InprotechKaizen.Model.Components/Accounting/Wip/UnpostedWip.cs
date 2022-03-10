using System;
using InprotechKaizen.Model.Accounting;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public class UnpostedWip : ICloneable
    {
        public int EntityKey { get; set; }
        public DateTime TransactionDate { get; set; }
        public int TransactionType { get; set; }
        public int? NameKey { get; set; }
        public int? CaseKey { get; set; }
        public int? StaffKey { get; set; }
        public int? AssociateKey { get; set; }

        public string InvoiceNumber { get; set; }
        public string VerificationNumber { get; set; }
        public int? RateNo { get; set; }
        public string WipCode { get; set; }
        public DateTime? TotalTime { get; set; }
        public short? TotalUnits { get; set; }
        public int? UnitsPerHour { get; set; }
        public decimal? ChargeOutRate { get; set; }
        public decimal? LocalValue { get; set; }
        public decimal? ForeignValue { get; set; }

        public string ForeignCurrency { get; set; }
        public decimal? ExchangeRate { get; set; }
        public decimal? DiscountValue { get; set; }
        public decimal? ForeignDiscount { get; set; }
        public decimal? VariableFeeAmount { get; set; }
        public int? VariableFeeType { get; set; }
        public string VariableCurrency { get; set; }
        public int? FeeCriteriaNo { get; set; }
        public int? FeeUniqueId { get; set; }
        public int? QuotationNo { get; set; }

        public decimal? LocalCost { get; set; }
        public decimal? ForeignCost { get; set; }
        public decimal? CostCalculation1 { get; set; }
        public decimal? CostCalculation2 { get; set; }
        public int? EnteredQuantity { get; set; }
        public int? ProductCode { get; set; }
        public bool? IsGeneratedInAdvance { get; set; }
        public int? NarrativeKey { get; set; }
        public string Narrative { get; set; }
        public string NarrativeTitle { get; set; }
        public string FeeType { get; set; }
        public bool ShouldUseSuppliedValues { get; set; }
        public string ActionKey { get; set; }
        public string WipCategory { get; set; }
        public decimal? BaseFeeAmount { get; set; }
        public decimal? AdditionalFee { get; set; }
        public string FeeTaxCode { get; set; }
        public decimal? FeeTaxAmount { get; set; }
        public int? AgeOfCase { get; set; }
        public int? MarginNo { get; set; }
        public int? DebugFlag { get; set; }
        public bool IsDraftWip { get; set; }
        public int? ItemTransNo { get; set; }
        public bool IsCreditWip { get; set; }
        public bool IsSeparateMargin { get; set; }
        public bool? ShouldSeparateMargin { get; set; }
        public decimal? MarginValue { get; set; }
        public decimal? ForeignMargin { get; set; }
        public decimal? DiscountForMargin { get; set; }
        public decimal? ForeignDiscountForMargin { get; set; }
        public string ReasonCode { get; set; }
        public bool ShouldReturnWipKey { get; set; }
        public bool IsBillingDiscount { get; set; }
        public bool ShouldSuppressCommit { get; set; }
        public bool ShouldSuppressPostToGeneralLedger { get; set; }
        public string ProtocolKey { get; set; }
        public string ProtocolDate { get; set; }
        public bool IsDiscount { get; set; }
        public bool IsMargin { get; set; }
        public string ProfitCentreCode { get; set; }
        public bool IsSplitDebtorWip { get; set; }
        public decimal? DebtorSplitPercentage { get; set; }
        public string DebtorNameTypeKey { get; set; }

        public object Clone()
        {
            return MemberwiseClone();
        }
    }

    public enum WipItemState
    {
        Empty,
        LocalValueOnly,
        ForeignValueOnly,
        LocalAndForeign
    }

    public static class UnpostedWipExt
    {
        public static WipItemState State(this UnpostedWip wipItem)
        {
            if (wipItem.LocalCost.HasValue && wipItem.ForeignCost.HasValue)
                return WipItemState.LocalAndForeign;

            if (wipItem.ForeignCost.HasValue)
                return WipItemState.ForeignValueOnly;

            return wipItem.LocalCost.HasValue ? WipItemState.LocalValueOnly : WipItemState.Empty;
        }

        public static bool IsSplitTimeByDebtor(this UnpostedWip wipItem)
        {
            return wipItem.TotalUnits.HasValue && !wipItem.LocalCost.HasValue;
        }

        public static bool IsServiceCharge(this UnpostedWip wipItem)
        {
            return wipItem.WipCategory == WipCategory.ServiceCharge;
        }
    }
}