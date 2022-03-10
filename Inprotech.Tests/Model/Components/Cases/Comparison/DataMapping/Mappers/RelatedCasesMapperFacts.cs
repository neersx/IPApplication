using System.Linq;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers;
using InprotechKaizen.Model.Ede.DataMapping;
using Xunit;
using ComparisonModel = InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class RelatedCasesMapperFacts
    {
        public class ExtractSourcesMethod
        {
            readonly RelatedCaseComparisonScenarioBuilder _relatedCaseScenarioBuilder = new RelatedCaseComparisonScenarioBuilder();

            [Fact]
            public void DoesNotReturnDuplicateCountryCodesForMapping()
            {
                _relatedCaseScenarioBuilder.RelatedCase = new ComparisonModel.RelatedCase
                {
                    CountryCode = "same same"
                };

                var relatedCases = new[]
                {
                    _relatedCaseScenarioBuilder.Build(),
                    _relatedCaseScenarioBuilder.Build()
                };

                var subject = new RelatedCasesMapper();
                var r = subject.ExtractSources(relatedCases);

                Assert.Single(r);
            }

            [Fact]
            public void DoesNotReturnDuplicateRelationshipForMapping()
            {
                _relatedCaseScenarioBuilder.RelatedCase = new ComparisonModel.RelatedCase
                {
                    Description = "same same"
                };

                var relatedCases = new[]
                {
                    _relatedCaseScenarioBuilder.Build(),
                    _relatedCaseScenarioBuilder.Build()
                };

                var subject = new RelatedCasesMapper();
                var r = subject.ExtractSources(relatedCases);

                Assert.Single(r);
            }

            [Fact]
            public void IgnoreThoseWithoutAnythingForMapping()
            {
                _relatedCaseScenarioBuilder.RelatedCase = new ComparisonModel.RelatedCase
                {
                    Description = null,
                    CountryCode = null
                };

                var relatedCases = new[]
                {
                    _relatedCaseScenarioBuilder.Build()
                };

                var subject = new RelatedCasesMapper();
                var r = subject.ExtractSources(relatedCases);

                Assert.Empty(r);
            }

            [Fact]
            public void ReturnsCountryCodeForMapping()
            {
                _relatedCaseScenarioBuilder.RelatedCase = new ComparisonModel.RelatedCase
                {
                    CountryCode = "RU"
                };

                var relatedCases = new[]
                {
                    _relatedCaseScenarioBuilder.Build()
                };

                var subject = new RelatedCasesMapper();
                var r = subject.ExtractSources(relatedCases).Single();

                Assert.Equal(KnownMapStructures.Country, r.TypeId);
                Assert.Equal("RU", r.Code);
                Assert.Null(r.Description);
            }

            [Fact]
            public void ReturnsDescriptionForMapping()
            {
                _relatedCaseScenarioBuilder.RelatedCase = new ComparisonModel.RelatedCase
                {
                    Description = "Priority"
                };

                var relatedCases = new[]
                {
                    _relatedCaseScenarioBuilder.Build()
                };

                var subject = new RelatedCasesMapper();
                var r = subject.ExtractSources(relatedCases).Single();

                Assert.Equal(KnownMapStructures.CaseRelationship, r.TypeId);
                Assert.Equal("Priority", r.Description);
                Assert.Null(r.Code);
            }
        }

        public class ApplyMappingMethod
        {
            const string RelationshipExtracted = "Priority";
            const string RelationshipCodeMapped = "BAS";

            const string CountryExtracted = "Singapore";
            const string CountryMapped = "SG";

            readonly ComparisonModel.RelatedCase _relatedCase = new ComparisonModel.RelatedCase();
            readonly RelatedCaseComparisonScenarioBuilder _relatedCaseScenarioBuilder = new RelatedCaseComparisonScenarioBuilder();

            [Fact]
            public void AppliesMappedCountryCodeToRelatedCase()
            {
                _relatedCaseScenarioBuilder.RelatedCase = _relatedCase;
                _relatedCase.CountryCode = CountryExtracted;

                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Country, CountryMapped, CountryExtracted)
                                  .Build();

                var subject = new RelatedCasesMapper();
                var r = (ComparisonScenario<ComparisonModel.RelatedCase>)
                    subject.ApplyMapping(
                                         _relatedCaseScenarioBuilder.Build(), new[] {mappedValue});

                Assert.Equal(CountryMapped, r.Mapped.CountryCode);
            }

            [Fact]
            public void AppliesMappedRelationshipCode()
            {
                _relatedCaseScenarioBuilder.RelatedCase = _relatedCase;
                _relatedCase.Description = RelationshipExtracted;

                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.CaseRelationship, RelationshipCodeMapped, null, RelationshipExtracted)
                                  .Build();

                var subject = new RelatedCasesMapper();
                var r = (ComparisonScenario<ComparisonModel.RelatedCase>)
                    subject.ApplyMapping(
                                         _relatedCaseScenarioBuilder.Build(), new[] {mappedValue});

                Assert.Equal(RelationshipCodeMapped, r.Mapped.RelationshipCode);
            }

            [Fact]
            public void IgnoresWhenMappedValuesNotFound()
            {
                _relatedCaseScenarioBuilder.RelatedCase = new ComparisonModel.RelatedCase();

                var subject = new RelatedCasesMapper();
                var r = (ComparisonScenario<ComparisonModel.RelatedCase>)
                    subject.ApplyMapping(_relatedCaseScenarioBuilder.Build(), Enumerable.Empty<MappedValue>());

                Assert.Null(r.Mapped.CountryCode);
                Assert.Null(r.Mapped.RelationshipCode);
            }

            [Fact]
            public void IgnoresWhenMappedValuesOutputIsEmpty()
            {
                _relatedCaseScenarioBuilder.RelatedCase = new ComparisonModel.RelatedCase
                {
                    CountryCode = "SG"
                };

                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Country, null, null, "SG")
                                  .Build();

                var subject = new RelatedCasesMapper();
                var r = (ComparisonScenario<ComparisonModel.RelatedCase>)
                    subject.ApplyMapping(
                                         _relatedCaseScenarioBuilder.Build(), new[] {mappedValue});

                Assert.Equal("SG", r.Mapped.CountryCode);
            }
        }
    }
}