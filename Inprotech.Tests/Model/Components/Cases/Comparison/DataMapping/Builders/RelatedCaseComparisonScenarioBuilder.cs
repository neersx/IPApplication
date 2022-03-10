using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class RelatedCaseComparisonScenarioBuilder : IBuilder<ComparisonScenario<RelatedCase>>
    {
        public RelatedCase RelatedCase { get; set; }

        public ComparisonScenario<RelatedCase> Build()
        {
            return new ComparisonScenario<RelatedCase>(
                                                       RelatedCase ?? new RelatedCaseBuilder().Build(),
                                                       ComparisonType.RelatedCases
                                                      );
        }
    }
}