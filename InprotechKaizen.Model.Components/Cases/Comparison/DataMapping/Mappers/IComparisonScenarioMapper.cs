using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public interface IComparisonScenarioMapper
    {
        IEnumerable<Source> ExtractSources(IEnumerable<ComparisonScenario> source);

        ComparisonScenario ApplyMapping(ComparisonScenario scenario, IEnumerable<MappedValue> mappedValues);
    }
}
