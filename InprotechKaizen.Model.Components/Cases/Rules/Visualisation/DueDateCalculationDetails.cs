using System;

namespace InprotechKaizen.Model.Components.Cases.Rules.Visualisation
{
    public class DueDateCalculationDetails
    {
        public int? CaseId { get; set; }
        public int? FromEvent { get; set; }
        public DateTime? FromDate { get; set; }
        public short? FromCycle { get; set; }
        public string FromEventDesc { get; set; }
        public int? RelativeCycle { get; set; }
        public string Operator { get; set; }
        public short? DeadlinePeriod { get; set; }
        public string PeriodType { get; set; }
        public int? EventDateFlag { get; set; }
        public bool? MustExist { get; set; }
        public decimal? WorkDay { get; set; }
        public string Adjustment { get; set; }
    }
}
