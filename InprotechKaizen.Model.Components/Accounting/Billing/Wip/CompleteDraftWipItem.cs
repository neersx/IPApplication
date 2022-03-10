using System;
using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public class CompleteDraftWipItem : DraftWip, IDraftWipFeeCalc
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
        public string FeeType2 { get; set; }
        public bool? IsFeeType2 { get; set; }
        public decimal? DisbursementBasicAmount { get; set; }
        public decimal? ServiceChargeBasicAmount { get; set; }
        public decimal? DisbursementExtendedAmount { get; set; }
        public decimal? ServiceChargeExtendedAmount { get; set; }
        public int? DefaultQuantity { get; set; }
        public string SourceType { get; set; }
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
        
        public bool? IsCreditFeesWip { get; set; }
        public bool IsAllowAdvanceBillDisbursement { get; set; }
        public bool IsAllowAdvanceBillServiceCharge { get; set; }   
    }
    
    public static class CompleteDraftWipItemExtension
    {
        public static IEnumerable<DraftWip> Split(this CompleteDraftWipItem draftWipItem)
        {
            if (draftWipItem == null) throw new ArgumentNullException(nameof(draftWipItem));

            if (draftWipItem.IsWipItem == true) yield break;

            if (!string.IsNullOrWhiteSpace(draftWipItem.DisbursementWipCode))
            {
                yield return ExtractDisbursementWip(draftWipItem);
            }

            if (!string.IsNullOrWhiteSpace(draftWipItem.ServiceChargeWipCode))
            {
                yield return ExtractServiceChargeWip(draftWipItem);
            }
        }

        static DraftWip ExtractDisbursementWip(CompleteDraftWipItem item)
        {
            var draftWip = (DraftWip) item.Clone();

            draftWip.ActivityId = item.DisbursementWipCode;
            draftWip.Activity = item.DisbursementWipDescription;
            draftWip.NarrativeId = item.DisbursementNarrativeId;
            draftWip.IsAdvanceBill = item.IsAllowAdvanceBillDisbursement;
            draftWip.Narrative = item.DisbursementNarrativeText;
            draftWip.NarrativeTitle = item.DisbursementNarrativeTitle;
            draftWip.LocalValue = item.DisbursementHomeAmount;
            draftWip.ForeignValue = item.DisbursementAmount;
            draftWip.ForeignCurrencyCode = item.DisbursementCurrency;
            draftWip.ForeignDiscount = item.DisbursementDiscountOriginal;
            draftWip.ForeignMargin = item.DisbursementMargin;
            draftWip.LocalDiscount = item.DisbursementHomeDiscount;
            draftWip.EnteredQuantity = item.DefaultQuantity;
            draftWip.LocalCost = item.DisbursementCostHome;
            draftWip.ForeignCost = item.DisbursementCostOriginal;
            draftWip.CostCalculation1 = item.DisbursementCostCalculation1;
            draftWip.CostCalculation2 = item.DisbursementCostCalculation2;
            draftWip.MarginNo = item.DisbursementMarginNo;
            draftWip.Margin = item.DisbursementHomeMargin;
            draftWip.WipCategory = item.DisbursementWipCategory;
            draftWip.WipTypeId = item.DisbursementWipTypeId;
            draftWip.WipCategorySortOrder = item.DisbursementWipCategorySortOrder;
            draftWip.LocalDiscountForMargin = item.DisbursementHomeDiscountForMargin;
            draftWip.ForeignDiscountForMargin = item.DisbursementDiscountForMargin;
            draftWip.BasicAmount = item.DisbursementBasicAmount;
            draftWip.ExtendedAmount = item.DisbursementExtendedAmount;
            draftWip.TaxCode = item.DisbursementTaxCode;
            draftWip.TaxAmount = item.DisbursementTaxAmount;

            return draftWip;
        }

        static DraftWip ExtractServiceChargeWip(CompleteDraftWipItem item)
        {
            var draftWip = (DraftWip) item.Clone();

            draftWip.ActivityId = item.ServiceChargeWipCode;
            draftWip.Activity = item.ServiceChargeWipDescription;
            draftWip.NarrativeId = item.ServiceChargeNarrativeId;
            draftWip.IsAdvanceBill = item.IsAllowAdvanceBillServiceCharge;
            draftWip.Narrative = item.ServiceChargeNarrativeText;
            draftWip.NarrativeTitle = item.ServiceChargeNarrativeTitle;
            draftWip.LocalValue = item.ServiceChargeHomeAmount;
            draftWip.ForeignValue = item.ServiceChargeAmount;
            draftWip.ForeignCurrencyCode = item.ServiceChargeCurrency;
            draftWip.ForeignDiscount = item.ServiceChargeDiscountOriginal;
            draftWip.ForeignMargin = item.ServiceChargeMargin;
            draftWip.LocalDiscount = item.ServiceChargeHomeDiscount;
            draftWip.EnteredQuantity = item.DefaultQuantity;
            draftWip.LocalCost = item.ServiceChargeCostHome;
            draftWip.ForeignCost = item.ServiceChargeCostOriginal;
            draftWip.CostCalculation1 = item.ServiceChargeCostCalculation1;
            draftWip.CostCalculation2 = item.ServiceChargeCostCalculation2;
            draftWip.MarginNo = item.ServiceChargeMarginNo;
            draftWip.Margin = item.ServiceChargeHomeMargin;
            draftWip.WipCategory = item.ServiceChargeWipCategory;
            draftWip.WipTypeId = item.ServiceChargeWipTypeId;
            draftWip.WipCategorySortOrder = item.ServiceChargeWipCategorySortOrder;
            draftWip.LocalDiscountForMargin = item.ServiceChargeHomeDiscountForMargin;
            draftWip.ForeignDiscountForMargin = item.ServiceChargeDiscountForMargin;
            draftWip.BasicAmount = item.ServiceChargeBasicAmount;
            draftWip.ExtendedAmount = item.ServiceChargeExtendedAmount;
            draftWip.TaxCode = item.ServiceChargeTaxCode;
            draftWip.TaxAmount = item.ServiceChargeTaxAmount;

            return draftWip;
        }
    }
}
