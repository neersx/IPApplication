using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class EventComparisonScenarioBuilder : IBuilder<ComparisonScenario<Event>>
    {
        public Event Event { get; set; }

        public ComparisonScenario<Event> Build()
        {
            return new ComparisonScenario<Event>(Event ?? new EventBuilder().Build(), ComparisonType.Events);
        }

        public IEnumerable<ComparisonScenario<Event>> Build(params Event[] events)
        {
            return (!events.Any()
                    ? new[] {new EventBuilder().Build()}
                    : events.AsEnumerable())
                .Select(e => new ComparisonScenario<Event>(e, ComparisonType.Events));
        }
    }
}