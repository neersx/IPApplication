using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class DateAdjustmentBuilder : IBuilder<DateAdjustment>
    {
        public string Id { get; set; }

        public string Description { get; set; }

        public decimal? AdjustDay { get; set; }

        public decimal? AdjustMonth { get; set; }

        public decimal? AdjustYear { get; set; }

        public short? AdjustAmount { get; set; }

        public string PeriodType { get; set; }

        public DateAdjustment Build()
        {
            return new DateAdjustment
            {
                Id = Id ?? Fixture.String("Adjustment"),
                Description = Description ?? Fixture.String("Adjustmentdesc"),
                AdjustDay = AdjustDay ?? Fixture.Decimal(),
                AdjustMonth = AdjustMonth ?? Fixture.Decimal(),
                AdjustYear = AdjustYear ?? Fixture.Decimal(),
                AdjustAmount = AdjustAmount ?? Fixture.Short(),
                PeriodType = PeriodType ?? Fixture.String("Periodtype")
            };
        }

        public DateAdjustment Build(decimal? day, decimal? month, decimal? year, short? amount = null)
        {
            return new DateAdjustment
            {
                Id = Fixture.String(),
                AdjustDay = day,
                AdjustMonth = month,
                AdjustYear = year,
                AdjustAmount = amount
            };
        }
    }
}