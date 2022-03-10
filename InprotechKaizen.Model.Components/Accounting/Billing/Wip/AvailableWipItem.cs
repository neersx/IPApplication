using System;
using System.Collections;
using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public class AvailableWipItem
    {
        public int UniqueReferenceId { get; set; }
        public int? CaseId { get; set; }
        public string CaseRef { get; set; }
        public int EntityId { get; set; }
        public int TransactionId { get; set; }
        public short WipSeqNo { get; set; }
        public string WipCode { get; set; }
        public string WipTypeId { get; set; }
        public string WipTypeDescription { get; set; }
        public string WipCategory { get; set; }
        public string WipCategoryDescription { get; set; }
        public string Description { get; set; }
        public bool IsRenewal { get; set; }
        public int? NarrativeId { get; set; }
        public string ShortNarrative { get; set; }
        public DateTime? TransactionDate { get; set; }
        public string StaffProfitCentre { get; set; }
        public string ProfitCentreDescription { get; set; }
        public DateTime? TotalTime { get; set; }
        public int? TotalUnits { get; set; }
        public int? UnitsPerHour { get; set; }
        public decimal? ChargeOutRate { get; set; }
        public decimal? VariableFeeAmount { get; set; }
        public int? VariableFeeType { get; set; }
        public string VariableFeeCurrency { get; set; }
        public string VariableFeeReason { get; set; }
        public string VariableFeeWipCode { get; set; }
        public int? FeeCriteriaNo { get; set; }
        public int? FeeUniqueId { get; set; }
        public string ReasonCode { get; set; }
        public decimal? Balance { get; set; }
        public decimal? LocalBilled { get; set; }

        public int? WriteDownPriority { get; set; }
        public bool WriteUpAllowed { get; set; }

        /* not populated */
        public decimal? CalculatedForeign { get; set; }
        public decimal? CalculatedForeignVariation { get; set; }

        public decimal? ForeignBalance { get; set; }
        public string ForeignCurrency { get; set; }
        public int? ForeignDecimalPlaces { get; set; }
        public decimal? ForeignBilled { get; set; }
        public decimal? LocalVariation { get; set; }
        public decimal? ForeignVariation { get; set; }
        public int? Status { get; set; }
        public string TaxCode { get; set; }
        public string TaxDescription { get; set; }
        public decimal? TaxRate { get; set; }
        public string StateTaxCode { get; set; }
        public string StaffName { get; set; }
        public string StaffSignOffName { get; set; }
        public int? StaffId { get; set; }
        public bool? IsDiscount { get; set; }
        public decimal? CostCalculation1 { get; set; }
        public decimal? CostCalculation2 { get; set; }
        public int? MarginNo { get; set; }
        public int WipCategorySortOrder { get; set; }
        public int? BillLineNo { get; set; }
        public bool IsDraft { get; set; }
        public bool? IsCreditWip { get; set; }
        public bool? IsAdvanceBill { get; set; }
        public bool? IsDiscountDisconnected { get; set; }
        public int? DraftWipRefId { get; set; }
        public string AutoWipWriteDownReason { get; set; }
        public DraftWip DraftWipData { get; set; }
        public DraftWipFeeCalc DraftFeeCalcData { get; set; }
        public bool? IsMargin { get; set; }
        public int? RateNoSortOrder { get; set; }
        public int WipTypeSortOrder { get; set; }
        public int WipCodeSortOrder { get; set; }
        public string Title { get; set; }

        public int? SplitWipRefKey { get; set; }
        public string SplitWipReasonCode { get; set; }
        public bool IsBillingDiscount { get; set; }
        public int? DebtorId { get; set; }
        public bool ShouldPreventWriteDown { get; set; }
        public bool ShowOnDebitNote { get; set; }
        public string GeneratedFromTaxCode { get; set; }
        public bool? IsHiddenForDraft { get; set; }
        public bool OneFeePerDebtor { get; set; }

        public int? BillItemEntityId { get; set; }
        public int? BillItemTransactionId { get; set; }

        public decimal? WipBuyRate { get; set; }
        public decimal? WipSellRate { get; set; }

        public decimal? BillBuyRate { get; set; }
        public decimal? BillSellRate { get; set; }

        public long? SplitGroupKey { get; set; }

        public int? AccountClientId { get; set; }

        public bool? IsFeeType { get; set; }

        public decimal? LocalTax => Math.Round(LocalBilled.GetValueOrDefault(0) * TaxRate.GetValueOrDefault(0) / 100, 2);

        // included for BillLineGenerator
        public bool IsWriteDown => LocalVariation < 0 && !string.IsNullOrEmpty(ReasonCode);
    }

    public static class AvailableWipItemExtension
    {
        public static IEnumerable<int> DistinctCaseIds(this IEnumerable<AvailableWipItem> items)
        {
            foreach (var item in items)
            {
                if (item.CaseId != null)
                    yield return (int) item.CaseId;
            }
        }

        public static AvailableWipItem ReverseSignsForCreditNote(this AvailableWipItem item)
        {
            if (item.IsDiscount == true) return item;
            if (item.IsCreditWip == true) return item;

            item.Balance *= -1;
            item.LocalBilled *= -1;
            item.LocalVariation *= -1;
            
            item.ForeignBilled *= -1;
            item.ForeignBalance *= -1;
            item.ForeignVariation *= -1;
            item.VariableFeeAmount *= -1;
            return item;
        }
    }
}