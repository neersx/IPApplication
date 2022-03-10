using System;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public class WipCost : ICloneable
    {
        public DateTime? TransactionDate { get; set; }
        public int? EntityKey { get; set; }
        public int? StaffKey { get; set; }
        public DateTime StartDateTime { get; set; }
        public int? NameKey { get; set; }
        public int? CaseKey { get; set; }
        public string WipCode { get; set; }
        public string DebtorNameTypeKey { get; set; }
        public int? ProductKey { get; set; }
        public bool? IsChargeGeneration { get; set; }
        public bool? IsServiceCharge { get; set; }
        public bool? UseSuppliedValues { get; set; }
        public DateTime? Hours { get; set; }
        public TimeSpan TimeCarriedForward { get; set; }
        public short? TimeUnits { get; set; }
        public short? UnitsPerHour { get; set; }
        public decimal? ChargeOutRate { get; set; }
        public decimal? LocalValueBeforeMargin { get; set; }
        public decimal? ForeignValueBeforeMargin { get; set; }
        public string CurrencyCode { get; set; }
        public decimal? ExchangeRate { get; set; }
        public decimal? LocalValue { get; set; }
        public decimal? ForeignValue { get; set; }
        public bool? IsMarginRequired { get; set; }
        public decimal? MarginValue { get; set; }
        public decimal? LocalDiscount { get; set; }
        public decimal? ForeignDiscount { get; set; }
        public decimal? LocalDiscountForMargin { get; set; }
        public decimal? ForeignDiscountForMargin { get; set; }
        public decimal? CostCalculation1 { get; set; }
        public decimal? CostCalculation2 { get; set; }
        public int? MarginNo { get; set; }
        public int? SupplierKey { get; set; }
        public bool? SplitTimeByDebtor { get; set; }
        public string ActionKey { get; set; }
        public int StaffClassKey { get; set; }
        public bool SeparateMarginMode { get; set; }
        public object Clone()
        {
            return MemberwiseClone();
        }
    }
}