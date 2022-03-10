using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using ComparisonModel = InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class NameComparisonScenarioBuilder : IBuilder<ComparisonScenario<ComparisonModel.Name>>
    {
        public ComparisonModel.Name Name { get; set; }

        public ComparisonScenario<ComparisonModel.Name> Build()
        {
            return new ComparisonScenario<ComparisonModel.Name>(
                                                                Name ?? new NameBuilder().Build(), ComparisonType.Names
                                                               );
        }
    }
}