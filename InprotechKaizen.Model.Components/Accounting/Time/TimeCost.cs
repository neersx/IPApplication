namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class TimeCost
    {
        public int EntryNo { get; set; }
        public int? StaffKey { get; set; }
        public int? NameKey { get; set; }
        public int? CaseKey { get; set; }
        public string WipCode { get; set; }
        public short? TimeUnits { get; set; }
        public short? UnitsPerHour { get; set; }
        public decimal? LocalValueBeforeMargin { get; set; }
        public decimal? ForeignValueBeforeMargin { get; set; }
        public string CurrencyCode { get; set; }
        public decimal? ExchangeRate { get; set; }
        public decimal? LocalValue { get; set; }
        public decimal? ForeignValue { get; set; }
        public decimal? LocalMargin { get; set; }
        public decimal? ForeignMargin { get; set; }
        public decimal? LocalDiscount { get; set; }
        public decimal? ForeignDiscount { get; set; }
        public decimal? LocalDiscountForMargin { get; set; }
        public decimal? ForeignDiscountForMargin { get; set; }
        public int? MarginNo { get; set; }
    }
}