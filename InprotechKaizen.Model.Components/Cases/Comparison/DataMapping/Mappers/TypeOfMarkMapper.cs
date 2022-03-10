using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Ede.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class TypeOfMarkMapper : IComparisonScenarioMapper
    {
        public IEnumerable<Source> ExtractSources(IEnumerable<ComparisonScenario> source)
        {
            var typeOfMark = source.OfType<ComparisonScenario<TypeOfMark>>();

            return typeOfMark
                   .Select(_ => new Source
                   {
                       TypeId = KnownMapStructures.TypeOfMark,
                       Description = _.ComparisonSource.Description
                   });
        }

        public ComparisonScenario ApplyMapping(ComparisonScenario scenario, IEnumerable<MappedValue> mappedValues)
        {
            var typeOfMark = (ComparisonScenario<TypeOfMark>)scenario;

            if (string.IsNullOrWhiteSpace(typeOfMark.ComparisonSource.Description))
                return scenario;

            var mapped =
                mappedValues.SingleOrDefault(_ =>
                                                 _.Source.TypeId == KnownMapStructures.TypeOfMark &&
                                                 _.Source.Description == typeOfMark.ComparisonSource.Description);

            if (string.IsNullOrWhiteSpace(mapped?.Output))
                return scenario;

            typeOfMark.Mapped.Id = int.TryParse(mapped.Output, out int v) ? (int?) v : null;
            return typeOfMark;
        }
    }
}
