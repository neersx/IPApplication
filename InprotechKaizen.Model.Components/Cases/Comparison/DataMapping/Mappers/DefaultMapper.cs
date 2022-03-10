using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class DefaultMapper : IComparisonScenarioMapper
    {
        public IEnumerable<Source> ExtractSources(IEnumerable<ComparisonScenario> source)
        {
            return Enumerable.Empty<Source>();
        }

        public ComparisonScenario ApplyMapping(ComparisonScenario scenario, IEnumerable<MappedValue> mappedValues)
        {
            return scenario;
        }
    }
}
