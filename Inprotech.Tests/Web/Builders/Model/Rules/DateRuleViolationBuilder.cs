using System;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class DateRuleViolationBuilder : IBuilder<DateRuleViolation>
    {
        public DateTime? DateToCompare { get; set; }
        public string ComparisonEvent { get; set; }
        public DateTime? ComparisonDate { get; set; }
        public bool? IsInvalid { get; set; }
        public string Message { get; set; }

        public DateRuleViolation Build()
        {
            return new DateRuleViolation
            {
                DateToCompare = DateToCompare ?? Fixture.Today(),
                ComparisonDate = ComparisonDate ?? Fixture.Today(),
                ComparisonEvent = Fixture.String(),
                IsInvalid = IsInvalid ?? true,
                Message = Fixture.String()
            };
        }
    }
}