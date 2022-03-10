using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class EventBuilder : Builder
    {
        public EventBuilder(IDbContext dbContext) : base(dbContext)
        {

        }

        public Event Create(string name = null,
                            short numberOfCyclesAllowed = 1,
                            bool? recalcEventData = null,
                            bool? suppressCalculation = null,
                            string clientImportanceLevel = null)
        {
            return InsertWithNewId(new Event
                                       {
                                           Description = Fixture.Prefix(name ?? Fixture.String(3)),
                                           NumberOfCyclesAllowed = numberOfCyclesAllowed,
                                           RecalcEventDate = recalcEventData,
                                           SuppressCalculation = suppressCalculation,
                                           ClientImportanceLevel = clientImportanceLevel
                                       });
        }
    }
}
