using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class VerifiedRelatedCaseComparisonScenarioBuilder : IBuilder<ComparisonScenario<VerifiedRelatedCase>>
    {
        public VerifiedRelatedCase RelatedCase { get; set; }

        public ComparisonScenario<VerifiedRelatedCase> Build()
        {
            return new ComparisonScenario<VerifiedRelatedCase>(
                                                       RelatedCase ?? new VerifiedRelatedCaseBuilder().Build(),
                                                       ComparisonType.VerifiedRelatedCases
                                                      );
        }
    }
}