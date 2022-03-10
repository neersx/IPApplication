using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    public class DueDateCalcBuilder : Builder
    {
        public DueDateCalcBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public DueDateCalc Create(ValidEvent ve)
        {
            var seq = (short?)ve.DueDateCalcs?.Count ?? 0;

            var newEvent = new EventBuilder(DbContext).Create();
            var d = new DueDateCalc(ve, seq)
            {
                Cycle = 1,
                FromEventId = newEvent.Id,
                FromEvent = newEvent,
                RelativeCycle = 1,
                Operator = "A",
                DeadlinePeriod = Fixture.Short(),
                PeriodType = "D",
                Inherited = ve.Inherited
            };

            return d;
        }
    }
}
