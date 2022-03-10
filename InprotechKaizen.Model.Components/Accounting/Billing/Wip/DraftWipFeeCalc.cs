namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public interface IDraftWipFeeCalc
    {
        string DisbursementCurrency { get; set; }
        decimal? DisbursementExchangeRate { get; set; }
        string ServiceChargeCurrency { get; set; }
        decimal? ServiceChargeExchangeRate { get; set; }
        string BillCurrency { get; set; }
        decimal? BillExchangeRate { get; set; }
        string DisbursementTaxCode { get; set; }
        string ServiceChargeTaxCode { get; set; }
        int? DisbursementNarrativeId { get; set; }
        string DisbursementNarrativeTitle { get; set; }
        string DisbursementNarrativeText { get; set; }
        int? ServiceChargeNarrativeId { get; set; }
        string ServiceChargeNarrativeTitle { get; set; }
        string ServiceChargeNarrativeText { get; set; }
        string DisbursementWipCode { get; set; }
        string ServiceChargeWipCode { get; set; }
        string DisbursementWipDescription { get; set; }
        string ServiceChargeWipDescription { get; set; }
        decimal? DisbursementAmount { get; set; }
        decimal? DisbursementHomeAmount { get; set; }
        decimal? DisbursementBillAmount { get; set; }
        decimal? ServiceChargeAmount { get; set; }
        decimal? ServiceChargeHomeAmount { get; set; }
        decimal? ServiceChargeBillAmount { get; set; }
        decimal? TotalHomeDiscount { get; set; }
        decimal? TotalBillDiscount { get; set; }
        decimal? DisbursementTaxAmount { get; set; }
        decimal? DisbursementTaxBillAmount { get; set; }
        decimal? DisbursementTaxHomeAmount { get; set; }
        decimal? ServiceChargeTaxAmount { get; set; }
        decimal? ServiceChargeTaxBillAmount { get; set; }
        decimal? ServiceChargeTaxHomeAmount { get; set; }
        decimal? DisbursementCostHome { get; set; }
        decimal? DisbursementCostOriginal { get; set; }
        decimal? DisbursementCostCalculation1 { get; set; }
        decimal? DisbursementCostCalculation2 { get; set; }
        decimal? ServiceChargeCostHome { get; set; }
        decimal? ServiceChargeCostOriginal { get; set; }
        decimal? ServiceChargeCostCalculation1 { get; set; }
        decimal? ServiceChargeCostCalculation2 { get; set; }
        decimal? DisbursementMargin { get; set; }
        decimal? DisbursementHomeMargin { get; set; }
        decimal? DisbursementBillMargin { get; set; }
        decimal? ServiceChargeMargin { get; set; }
        decimal? ServiceChargeHomeMargin { get; set; }
        decimal? ServiceChargeBillMargin { get; set; }
        int? DisbursementMarginNo { get; set; }
        int? ServiceChargeMarginNo { get; set; }
        decimal? DisbursementDiscountOriginal { get; set; }
        decimal? DisbursementHomeDiscount { get; set; }
        decimal? DisbursementBillDiscount { get; set; }
        decimal? ServiceChargeDiscountOriginal { get; set; }
        decimal? ServiceChargeHomeDiscount { get; set; }
        decimal? ServiceChargeBillDiscount { get; set; }
        int? FeeCriteriaNo { get; set; }
        int? FeeUniqueId { get; set; }
        string FeeType { get; set; }
        string FeeType2 { get; set; }
        bool? IsFeeType { get; set; }
        bool? IsFeeType2 { get; set; }
        decimal? DisbursementBasicAmount { get; set; }
        decimal? ServiceChargeBasicAmount { get; set; }
        decimal? DisbursementExtendedAmount { get; set; }
        decimal? ServiceChargeExtendedAmount { get; set; }
        int? DefaultQuantity { get; set; }
        string SourceType { get; set; }
        string RowKey { get; set; }
        int? DraftWipRefId { get; set; }
        string DisbursementWipTypeId { get; set; }
        string DisbursementWipCategory { get; set; }
        int? DisbursementWipCategorySortOrder { get; set; }
        string ServiceChargeWipTypeId { get; set; }
        string ServiceChargeWipCategory { get; set; }
        int? ServiceChargeWipCategorySortOrder { get; set; }
        decimal? DisbursementHomeDiscountForMargin { get; set; }
        decimal? DisbursementDiscountForMargin { get; set; }
        decimal? ServiceChargeHomeDiscountForMargin { get; set; }
        decimal? ServiceChargeDiscountForMargin { get; set; }
        bool? IsSeparateMargin { get; set; }
    }

    public class DraftWipFeeCalc : IDraftWipFeeCalc
    {
        public string DisbursementCurrency { get; set; }
        public decimal? DisbursementExchangeRate { get; set; }
        public string ServiceChargeCurrency { get; set; }
        public decimal? ServiceChargeExchangeRate { get; set; }
        public string BillCurrency { get; set; }
        public decimal? BillExchangeRate { get; set; }
        public string DisbursementTaxCode { get; set; }
        public string ServiceChargeTaxCode { get; set; }
        public int? DisbursementNarrativeId { get; set; }
        public string DisbursementNarrativeTitle { get; set; }
        public string DisbursementNarrativeText { get; set; }
        public int? ServiceChargeNarrativeId { get; set; }
        public string ServiceChargeNarrativeTitle { get; set; }
        public string ServiceChargeNarrativeText { get; set; }
        public string DisbursementWipCode { get; set; }
        public string ServiceChargeWipCode { get; set; }
        public string DisbursementWipDescription { get; set; }
        public string ServiceChargeWipDescription { get; set; }
        public decimal? DisbursementAmount { get; set; }
        public decimal? DisbursementHomeAmount { get; set; }
        public decimal? DisbursementBillAmount { get; set; }
        public decimal? ServiceChargeAmount { get; set; }
        public decimal? ServiceChargeHomeAmount { get; set; }
        public decimal? ServiceChargeBillAmount { get; set; }
        public decimal? TotalHomeDiscount { get; set; }
        public decimal? TotalBillDiscount { get; set; }
        public decimal? DisbursementTaxAmount { get; set; }
        public decimal? DisbursementTaxBillAmount { get; set; }
        public decimal? DisbursementTaxHomeAmount { get; set; }
        public decimal? ServiceChargeTaxAmount { get; set; }
        public decimal? ServiceChargeTaxBillAmount { get; set; }
        public decimal? ServiceChargeTaxHomeAmount { get; set; }
        public decimal? DisbursementCostHome { get; set; }
        public decimal? DisbursementCostOriginal { get; set; }
        public decimal? DisbursementCostCalculation1 { get; set; }
        public decimal? DisbursementCostCalculation2 { get; set; }
        public decimal? ServiceChargeCostHome { get; set; }
        public decimal? ServiceChargeCostOriginal { get; set; }
        public decimal? ServiceChargeCostCalculation1 { get; set; }
        public decimal? ServiceChargeCostCalculation2 { get; set; }
        public decimal? DisbursementMargin { get; set; }
        public decimal? DisbursementHomeMargin { get; set; }
        public decimal? DisbursementBillMargin { get; set; }
        public decimal? ServiceChargeMargin { get; set; }
        public decimal? ServiceChargeHomeMargin { get; set; }
        public decimal? ServiceChargeBillMargin { get; set; }
        public int? DisbursementMarginNo { get; set; }
        public int? ServiceChargeMarginNo { get; set; }
        public decimal? DisbursementDiscountOriginal { get; set; }
        public decimal? DisbursementHomeDiscount { get; set; }
        public decimal? DisbursementBillDiscount { get; set; }
        public decimal? ServiceChargeDiscountOriginal { get; set; }
        public decimal? ServiceChargeHomeDiscount { get; set; }
        public decimal? ServiceChargeBillDiscount { get; set; }
        public int? FeeCriteriaNo { get; set; }
        public int? FeeUniqueId { get; set; }
        public string FeeType { get; set; }
        public string FeeType2 { get; set; }
        public bool? IsFeeType { get; set; }
        public bool? IsFeeType2 { get; set; }
        public decimal? DisbursementBasicAmount { get; set; }
        public decimal? ServiceChargeBasicAmount { get; set; }
        public decimal? DisbursementExtendedAmount { get; set; }
        public decimal? ServiceChargeExtendedAmount { get; set; }
        public int? DefaultQuantity { get; set; }
        public string SourceType { get; set; }
        public string RowKey { get; set; }
        public int? DraftWipRefId { get; set; }
        public string DisbursementWipTypeId { get; set; }
        public string DisbursementWipCategory { get; set; }
        public int? DisbursementWipCategorySortOrder { get; set; }
        public string ServiceChargeWipTypeId { get; set; }
        public string ServiceChargeWipCategory { get; set; }
        public int? ServiceChargeWipCategorySortOrder { get; set; }
        public decimal? DisbursementHomeDiscountForMargin { get; set; }
        public decimal? DisbursementDiscountForMargin { get; set; }
        public decimal? ServiceChargeHomeDiscountForMargin { get; set; }
        public decimal? ServiceChargeDiscountForMargin { get; set; }
        public bool? IsSeparateMargin { get; set; }
    }
}