using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Ede.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class NamesMapper : IComparisonScenarioMapper
    {
        public IEnumerable<Source> ExtractSources(IEnumerable<ComparisonScenario> source)
        {
            var names = source.OfType<ComparisonScenario<Name>>().ToArray();

            var countryMapping = names
                .Where(_ => !string.IsNullOrWhiteSpace(_.ComparisonSource.CountryCode))
                .DistinctBy(_ => _.ComparisonSource.CountryCode)
                .Select(_ => new Source
                             {
                                 TypeId = KnownMapStructures.Country,
                                 Code = _.ComparisonSource.CountryCode
                             });

            var nameTypesMapping = names
                .Where(_ => !string.IsNullOrWhiteSpace(_.ComparisonSource.NameTypeCode))
                .DistinctBy(_ => _.ComparisonSource.NameTypeCode)
                .Select(_ => new Source
                             {
                                 TypeId = KnownMapStructures.NameType,
                                 Description = _.ComparisonSource.NameTypeCode
                             });

            return countryMapping.Concat(nameTypesMapping);
        }

        public ComparisonScenario ApplyMapping(ComparisonScenario scenario, IEnumerable<MappedValue> mappedValues)
        {
            var name = (ComparisonScenario<Name>)scenario;

            var mv = mappedValues.ToArray();

            ApplyCountryCodeMapping(name, mv);

            ApplyNameTypeMapping(name, mv);

            return name;
        }

        static void ApplyCountryCodeMapping(ComparisonScenario<Name> name, IEnumerable<MappedValue> mappedValues)
        {
            if (string.IsNullOrWhiteSpace(name.ComparisonSource.CountryCode))
                return;

            var mapped =
                mappedValues.SingleOrDefault(_ =>
                    _.Source.TypeId == KnownMapStructures.Country &&
                    _.Source.Code == name.ComparisonSource.CountryCode);

            if (mapped == null || string.IsNullOrWhiteSpace(mapped.Output))
                return;

            name.Mapped.CountryCode = mapped.Output;
        }

        static void ApplyNameTypeMapping(ComparisonScenario<Name> name, IEnumerable<MappedValue> mappedValues)
        {
            if (string.IsNullOrWhiteSpace(name.ComparisonSource.NameTypeCode))
                return;

            var mapped =
                mappedValues.SingleOrDefault(_ =>
                    _.Source.TypeId == KnownMapStructures.NameType &&
                    _.Source.Description == name.ComparisonSource.NameTypeCode);

            if (mapped == null || string.IsNullOrWhiteSpace(mapped.Output))
                return;

            name.Mapped.NameTypeCode = mapped.Output;
        }
    }
}