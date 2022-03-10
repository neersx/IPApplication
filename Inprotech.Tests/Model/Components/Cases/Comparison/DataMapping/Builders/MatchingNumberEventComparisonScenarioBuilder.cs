using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class MatchingNumberEventComparisonScenarioBuilder : IBuilder<ComparisonScenario<MatchingNumberEvent>>
    {
        public MatchingNumberEvent Event { get; set; }

        public ComparisonScenario<MatchingNumberEvent> Build()
        {
            return new ComparisonScenario<MatchingNumberEvent>(Event ?? new MatchingNumberEventBuilder().Build(), ComparisonType.MatchingNumberEvents);
        }

        public IEnumerable<ComparisonScenario<MatchingNumberEvent>> Build(params MatchingNumberEvent[] events)
        {
            return (!events.Any()
                    ? new[] {new MatchingNumberEventBuilder().Build()}
                    : events.AsEnumerable())
                .Select(e => new ComparisonScenario<MatchingNumberEvent>(e, ComparisonType.MatchingNumberEvents));
        }
    }
}