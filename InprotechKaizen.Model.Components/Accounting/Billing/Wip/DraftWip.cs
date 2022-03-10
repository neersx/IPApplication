using System;
using Inprotech.Infrastructure.DateTimeHelpers;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public class DraftWip : ICloneable
    {
        public int? EntityId { get; set; }
        public int? TransactionId { get; set; }
        public short? WipSequenceNo { get; set; }
        public DateTime? EntryDate { get; set; }
        public int? RateId { get; set; }
        public string RateDescription { get; set; }
        public string WipCategory { get; set; }
        public string WipCode { get; set; }
        public string ActivityId { get; set; }
        public string Activity { get; set; }
        public int? NameId { get; set; }
        public int? DisplayNameId { get; set; }
        public string Name { get; set; }
        public string NameCode { get; set; }
        public int? CaseId { get; set; }
        public string CaseReference { get; set; }
        public int? StaffId { get; set; }
        public string StaffName { get; set; }
        public string StaffSignOffName { get; set; }
        public string StaffCode { get; set; }
        public int? TotalTime { get; set; }
        public short? TotalUnits { get; set; }
        public short? UnitsPerHour { get; set; }
        public decimal? ChargeOutRate { get; set; }
        public int? AssociateNameId { get; set; }
        public string AssociateName { get; set; }
        public string AssociateCode { get; set; }
        public string InvoiceNumber { get; set; }
        public string ForeignCurrencyCode { get; set; }
        public decimal? ForeignValue { get; set; }
        public decimal? ForeignDiscount { get; set; }
        public decimal? ExchangeRate { get; set; }
        public decimal? LocalValue { get; set; }
        public decimal? VariableFeeAmount { get; set; }
        public decimal? LocalDiscount { get; set; }
        public decimal? Balance { get; set; }
        public decimal? LocalCost { get; set; }
        public decimal? Margin { get; set; }
        public decimal? ForeignMargin { get; set; }
        public decimal? ForeignCost { get; set; }
        public int? EnteredQuantity { get; set; }
        public int? EnteredChargeQuantity { get; set; }
        public bool IsDiscount { get; set; }
        public decimal? ForeignBalance { get; set; }
        public decimal? CostCalculation1 { get; set; }
        public decimal? CostCalculation2 { get; set; }
        public int? ProductId { get; set; }
        public string ProductCode { get; set; }
        public string Product { get; set; }
        public string ProductChargeId { get; set; }
        public string ProductChargeCode { get; set; }
        public string ProductCharge { get; set; }
        public int? NarrativeId { get; set; }
        public string Narrative { get; set; }
        public string NarrativeTitle { get; set; }
        public string NarrativeCode { get; set; }
        public string Notes { get; set; }
        public short? Status { get; set; }
        public int? QuotationId { get; set; }
        public string StaffFamilyId { get; set; }
        public string StaffOfficeCode { get; set; }
        public string VerificationCode { get; set; }
        public string LocalCurrencyCode { get; set; }
        public string LocalDecimalPlaces { get; set; }
        public bool? ShouldUseSuppliedValues { get; set; }
        public bool? IsCreditWip { get; set; }
        public bool? IsWipItem { get; set; }
        public int? MarginNo { get; set; }
        public int? Cycle { get; set; }
        public bool? IsQuantityAmountChange { get; set; }
        public bool? IsAdvanceBill { get; set; }
        public string RowKey { get; set; }
        public int? DraftWipRefId { get; set; }
        public string WipTypeId { get; set; }
        public int? WipCategorySortOrder { get; set; }
        public bool? IsSeparateMargin { get; set; }
        public decimal? LocalDiscountForMargin { get; set; }
        public decimal? ForeignDiscountForMargin { get; set; }
        public bool? IsRenewal { get; set; }
        public bool IsBillingDiscount { get; set; }
        public string IsGeneratedFromTaxCode { get; set; }
        public bool IsOneFeePerDebtor { get; set; }
        public string ProfitCentreCode { get; set; }
        public string ProfitCentre { get; set; }
        public bool IsSplitDebtorWip { get; set; }
        public decimal? DebtorSplitPercentage { get; set; }
        public long? SplitGroupKey { get; set; }
        public string FeeType { get; set; }
        public bool? IsFeeType { get; set; }
        public decimal? BasicAmount { get; set; }
        public decimal? ExtendedAmount { get; set; }
        public string TaxCode { get; set; }
        public decimal? TaxAmount { get; set; }
        public int? RateNoSort { get; set; }

        public bool IsBillingDiscountOrStampFee => IsBillingDiscount || !string.IsNullOrEmpty(IsGeneratedFromTaxCode);

        public object Clone()
        {
            return MemberwiseClone();
        }
    }

    public static class DraftWipExtension
    {
        public static DraftWip ReverseSignsForCreditFeeCharges(this CompleteDraftWipItem item, Func<CompleteDraftWipItem, bool> predicate)
        {
            return !predicate(item) 
                ? item
                : DoReverseSignsForCreditFeeCharges(item);
        }

        public static DraftWip ReverseSignsForCreditFeeCharges(this DraftWip item, Func<DraftWip, bool> predicate)
        {
            return !predicate(item)
                ? item
                : DoReverseSignsForCreditFeeCharges(item);
        }

        static DraftWip DoReverseSignsForCreditFeeCharges(this DraftWip item)
        {
            item.LocalValue *= -1;
            item.LocalCost *= -1;
            item.Margin *= -1;
            item.CostCalculation1 *= -1;
            item.CostCalculation2 *= -1;

            if (!string.IsNullOrWhiteSpace(item.ForeignCurrencyCode))
            {
                item.ForeignValue *= -1;
                item.ForeignCost *= -1;
                item.ForeignMargin *= -1;
            }

            return item;
        }

        public static DateTime? TotalTimeInDateTime(this DraftWip draftWip)
        {
            return NumberToDateTime.Convert(draftWip.TotalTime);
        }
    }
}