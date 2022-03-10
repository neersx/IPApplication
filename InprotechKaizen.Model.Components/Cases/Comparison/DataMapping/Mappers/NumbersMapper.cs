using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Ede.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class NumbersMapper : IComparisonScenarioMapper
    {
        public IEnumerable<Source> ExtractSources(IEnumerable<ComparisonScenario> source)
        {
            var officialNumbers = source.OfType<ComparisonScenario<OfficialNumber>>();

            return officialNumbers
                .DistinctBy(_ => _.ComparisonSource.NumberType)
                .Select(_ => new Source
                             {
                                 TypeId = KnownMapStructures.NumberType,
                                 Code = _.ComparisonSource.NumberType
                             });
        }

        public ComparisonScenario ApplyMapping(ComparisonScenario scenario, IEnumerable<MappedValue> mappedValues)
        {
            var number = (ComparisonScenario<OfficialNumber>)scenario;

            if (string.IsNullOrWhiteSpace(number.ComparisonSource.NumberType))
                return scenario;

            var mapped =
                mappedValues.SingleOrDefault(_ =>
                    _.Source.TypeId == KnownMapStructures.NumberType &&
                    _.Source.Code == number.ComparisonSource.NumberType);

            if (string.IsNullOrWhiteSpace(mapped?.Output))
                return scenario;

            number.Mapped.NumberType = mapped.Output;

            return number;
        }
    }
}