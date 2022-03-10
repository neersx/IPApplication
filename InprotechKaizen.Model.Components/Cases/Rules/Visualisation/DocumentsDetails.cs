namespace InprotechKaizen.Model.Components.Cases.Rules.Visualisation
{
    public class DocumentsDetails
    {
        public short? LeadTime { get; set; }
        public string PeriodType { get; set; }
        public short? Frequency { get; set; }
        public string FreqPeriodType { get; set; }
        public short? StopTime { get; set; }
        public string StopTimePeriodType { get; set; }
        public short? MaxLetters { get; set; }
        public short? LetterNo { get; set; }
        public string LetterName { get; set; }
        public bool? CheckOverride { get; set; }
        public short UpdateEvent { get; set; }
        public string LetterFee { get; set; }
        public int PayFeeCode { get; set; }
        public bool? EstimateFlag { get; set; }
        public bool? DirectPayFlag { get; set; }
    }
}