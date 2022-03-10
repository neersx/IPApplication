using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Web.Builders.Model.Cases.Events
{
    public class EventBuilder : IBuilder<Event>
    {
        public int Id { get; set; } 
        public short? NumCyclesAllowed { get; set; }
        public string Code { get; set; }
        public string Description { get; set; }
        public bool? ShouldPoliceImmediate { get; set; }
        public Importance Importance { get; set; }
        public string ControllingAction { get; set; }

        public string ClientImportanceLevel { get; set; }

        public Event Build()
        {
            return new Event
            {
                Id =Id==0?Fixture.Integer() : Id,
                Code = Code ?? Fixture.UniqueName(),
                Description = Description ?? Fixture.UniqueName(),
                NumberOfCyclesAllowed = NumCyclesAllowed ?? Fixture.Short(),
                ShouldPoliceImmediate = ShouldPoliceImmediate ?? false,
                ImportanceLevel = Importance?.Level,
                InternalImportance = Importance ?? new ImportanceBuilder().Build(),
                ControllingAction = ControllingAction,
                ClientImportanceLevel = ClientImportanceLevel
            };
        }

        public static EventBuilder ForNonCyclicEvent()
        {
            return new EventBuilder {NumCyclesAllowed = 1};
        }

        public static EventBuilder ForCyclicEvent(short maxCycle = 9999)
        {
            return new EventBuilder {NumCyclesAllowed = maxCycle};
        }
    }
}