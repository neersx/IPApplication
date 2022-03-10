using System;

namespace InprotechKaizen.Model.Rules
{
    public class DateRuleViolation
    {
        public DateTime DateToCompare { get; set; }
        public string ComparisonEvent { get; set; }
        public DateTime ComparisonDate { get; set; }
        public bool IsInvalid { get; set; }
        public string Message { get; set; }
    }
}