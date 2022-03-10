using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class ValidEventBuilder : Builder
    {
        public ValidEventBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public ValidEvent Create(Criteria criteria = null, Event @event = null, string description = null, bool inherited = false, Importance importance = null)
        {
            return Insert(new ValidEvent(criteria ?? new CriteriaBuilder(DbContext).Create(),
                                         @event ?? new EventBuilder(DbContext).Create(),
                                         description ?? Fixture.String(4))
            {
                Inherited = inherited ? 1 : 0,
                NumberOfCyclesAllowed = 1,
                Importance = importance ?? new ImportanceBuilder(DbContext).Create(),
                DatesLogicComparison = 0
            });
        }
    }
}
