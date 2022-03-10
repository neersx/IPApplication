using System;
using InprotechKaizen.Model.Accounting;

namespace Inprotech.Tests.Web.Builders.Model.Accounting
{
    public class PeriodBuilder : IBuilder<Period>
    {
        public string Label { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public SystemIdentifier? ClosedForModules { get; set; }
        public DateTime? PostingCommenced { get; set; }
        public Period Build()
        {
            return new Period
            {
                ClosedForModules = ClosedForModules,
                Label = Label ?? Fixture.String(),
                StartDate = StartDate ?? Fixture.Today(),
                EndDate = EndDate ?? Fixture.Today(),
                PostingCommenced = PostingCommenced
            };
        }
    }
}