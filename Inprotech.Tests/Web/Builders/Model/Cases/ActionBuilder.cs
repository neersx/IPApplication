using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class ActionBuilder : IBuilder<Action>
    {
        public string Id { get; set; }

        public string Name { get; set; }

        public string ImportanceLevel { get; set; }

        public short NumberOfCyclesAllowed { get; set; }

        public decimal? ActionType { get; set; }

        public Action Build()
        {
            var action = new Action(Name ?? Fixture.String("Name"), numberOfCyclesAllowed: NumberOfCyclesAllowed, id: Id ?? Fixture.String())
            {
                ImportanceLevel = ImportanceLevel ?? "1",
                ActionType = ActionType ?? 1
            };
            return action;
        }
    }
}