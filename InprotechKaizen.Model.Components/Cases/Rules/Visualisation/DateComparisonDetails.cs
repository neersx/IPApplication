using System;

namespace InprotechKaizen.Model.Components.Cases.Rules.Visualisation
{
    public class DateComparisonDetails
    {
        public int? CaseId { get; set; }
        public int? FromEvent { get; set; }
        public DateTime? FromDate { get; set; }
        public string FromEventDesc { get; set; }
        public short? RelativeCycle { get; set; }
        public short? EventDateFlag { get; set; }
        public string Comparison { get; set; }
        public int? CompareEvent { get; set; }
        public DateTime? ComparisonDate { get; set; }
        public string CompareEventDesc { get; set; }
        public short? CompareCycle { get; set; }
        public int? CompareEventFlag { get; set; }
        public DateTime? CompareDate { get; set; }
        public bool? CompareSystemDate { get; set; }
        
    }
}
