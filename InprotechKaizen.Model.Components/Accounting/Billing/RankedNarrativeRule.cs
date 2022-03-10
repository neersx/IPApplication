namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public class RankedNarrativeRule
    {
        public int NarrativeRuleId { get; set; }
        public short NarrativeId { get; set; }
        public int? StaffId { get; set; }
        public string CaseTypeId { get; set; }
        public string PropertyTypeId { get; set; }
        public string CaseCategoryId { get; set; }
        public string SubTypeId { get; set; }
        public int? TypeOfMark { get; set; }
        public string CountryCode { get; set; }
        public bool? IsLocalCountry { get; set; }
        public bool? IsForeignCountry { get; set; }
        public int? DebtorId { get; set; }
        public string BestFitScore { get; set; }
    }
}