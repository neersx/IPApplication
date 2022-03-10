using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class OfficialNumberComparisonScenarioBuilder : IBuilder<ComparisonScenario<OfficialNumber>>
    {
        public OfficialNumber OfficialNumber { get; set; }

        public ComparisonScenario<OfficialNumber> Build()
        {
            return new ComparisonScenario<OfficialNumber>(
                                                          OfficialNumber ?? new OfficialNumberBuilder().Build(), ComparisonType.OfficialNumbers
                                                         );
        }
    }
}