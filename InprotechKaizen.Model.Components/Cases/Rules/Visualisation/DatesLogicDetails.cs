using System;

namespace InprotechKaizen.Model.Components.Cases.Rules.Visualisation
{
    public class DatesLogicDetails
    {
        public int? DateType { get; set; }
        public string Operator { get; set; }
        public int? CompareEvent { get; set; }
        public string CompareEventDesc { get; set; }
        public bool? MustExist { get; set; }
        public int? RelativeCycle { get; set; }
        public int? ComparisonCaseId { get; set; }
        public string ComparisonIrn { get; set; }
        public int? ComparisonEventNo { get; set; }
        public short? ComparisonCycleNo { get; set; }
        public DateTime? ComparisonDate { get; set; }
        public string CaseRelationship { get; set; }
        public string CompareRelationship { get; set; }
        public int? CompareDateType { get; set; }
        public decimal? DisplayErrorFlag { get; set; }
        public string ErrorMessage { get; set; }
    }
}
