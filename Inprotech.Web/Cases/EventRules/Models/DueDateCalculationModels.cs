using System.Collections.Generic;

namespace Inprotech.Web.Cases.EventRules.Models
{
    public class DueDateCalculationItem
    {
        public bool? Or { get; set; }
        public string FormattedDescription { get; set; }
        public string CalculatedFromLabel { get; set; }
        public string FromDateFormatted { get; set; }
        public int? EventKey { get; set; }
        public int? CaseKey { get; set; }
        public string CaseReference { get; set; }
        public short? Cycle { get; set; }
        public bool? MustExist { get; set; }
    }

    public class DueDateComparisonItem
    {
        public string LeftHandSide { get; set; }
        public string RightHandSide { get; set; }
        public string Comparison { get; set; }
        public int? LeftHandSideEventKey { get; set; }
        public int? RightHandSideEventKey { get; set; }
    }

    public class DueDateSatisfiedByItem
    {
        public int? EventKey { get; set; }
        public string FormattedDescription { get; set; }
    }

    public class DueDateCalculationInfo
    {
        public string Heading { get; set; }
        public IEnumerable<DueDateCalculationItem> DueDateCalculation { get; set; }
        public string StandingInstructionInfo { get; set; }
        public string DueDateComparisonInfo { get; set; }
        public IEnumerable<DueDateComparisonItem> DueDateComparison { get; set; }
        public IEnumerable<DueDateSatisfiedByItem> DueDateSatisfiedBy { get; set; }
        public string ExtensionInfo { get; set; }
        public bool HasSaveDueDateInfo { get; set; }
        public bool HasRecalculateInfo { get; set; }
    }
}