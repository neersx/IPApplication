using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class GoodsServicesComparisonScenarioBuilder : IBuilder<ComparisonScenario<GoodsServices>>
    {
        public GoodsServices GoodsServices { get; set; }

        public ComparisonScenario<GoodsServices> Build()
        {
            return new ComparisonScenario<GoodsServices>(
                                                         GoodsServices ?? new GoodsServicesBuilder().Build(),
                                                         ComparisonType.GoodsServices);
        }
    }
}