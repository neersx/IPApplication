using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Ede.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class RelatedCasesMapper : IComparisonScenarioMapper
    {
        public IEnumerable<Source> ExtractSources(IEnumerable<ComparisonScenario> source)
        {
            var relatedCases = source.OfType<ComparisonScenario<RelatedCase>>().ToArray();

            var countryMapping = relatedCases
                .Where(_ => !string.IsNullOrWhiteSpace(_.ComparisonSource.CountryCode))
                .DistinctBy(_ => _.ComparisonSource.CountryCode)
                .Select(_ => new Source
                             {
                                 TypeId = KnownMapStructures.Country,
                                 Code = _.ComparisonSource.CountryCode
                             });

            var caseRelationMapping = relatedCases
                .Where(_ => !string.IsNullOrWhiteSpace(_.ComparisonSource.Description))
                .DistinctBy(_ => _.ComparisonSource.Description)
                .Select(_ => new Source
                             {
                                 TypeId = KnownMapStructures.CaseRelationship,
                                 Description = _.ComparisonSource.Description
                             });

            return countryMapping.Concat(caseRelationMapping);
        }

        public ComparisonScenario ApplyMapping(ComparisonScenario scenario, IEnumerable<MappedValue> mappedValues)
        {
            var relatedCase = scenario as ComparisonScenario<RelatedCase>;

            var mv = mappedValues.ToArray();

            ApplyCountryCodeMapping(relatedCase, mv);

            ApplyRelationshipCodeMapping(relatedCase, mv);

            return relatedCase;
        }

        static void ApplyCountryCodeMapping(ComparisonScenario<RelatedCase> relatedCase, IEnumerable<MappedValue> mappedValues)
        {
            if (string.IsNullOrWhiteSpace(relatedCase.ComparisonSource.CountryCode))
                return;

            var mapped =
                mappedValues.SingleOrDefault(_ =>
                    _.Source.TypeId == KnownMapStructures.Country &&
                    _.Source.Code == relatedCase.ComparisonSource.CountryCode);

            if (mapped == null || string.IsNullOrWhiteSpace(mapped.Output))
                return;

            relatedCase.Mapped.CountryCode = mapped.Output;
        }

        static void ApplyRelationshipCodeMapping(ComparisonScenario<RelatedCase> relatedCase, IEnumerable<MappedValue> mappedValues)
        {
            if (string.IsNullOrWhiteSpace(relatedCase.ComparisonSource.Description))
                return;

            var mapped =
                mappedValues.SingleOrDefault(_ =>
                    _.Source.TypeId == KnownMapStructures.CaseRelationship &&
                    _.Source.Description == relatedCase.ComparisonSource.Description);

            if (mapped == null || string.IsNullOrWhiteSpace(mapped.Output))
                return;

            relatedCase.Mapped.RelationshipCode = mapped.Output;
        }
    }
}