using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class TypeOfMarkComparisonScenarioBuilder : IBuilder<ComparisonScenario<TypeOfMark>>
    {
        public TypeOfMark TypeOfMark { get; set; }

        public ComparisonScenario<TypeOfMark> Build()
        {
            return new ComparisonScenario<TypeOfMark>(TypeOfMark ?? new TypeOfMark(), ComparisonType.TypeOfMark);
        }
    }
}
