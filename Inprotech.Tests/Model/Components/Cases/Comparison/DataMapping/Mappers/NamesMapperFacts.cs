using System.Linq;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers;
using InprotechKaizen.Model.Ede.DataMapping;
using Xunit;
using NameExtracted = InprotechKaizen.Model.Components.Cases.Comparison.Models.Name;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class NamesMapperFacts
    {
        public class ExtractSourcesMethod
        {
            readonly NameComparisonScenarioBuilder _nameScenarioBuilder = new NameComparisonScenarioBuilder();

            [Fact]
            public void DoesNotReturnDuplicateCountryCodesForMapping()
            {
                _nameScenarioBuilder.Name = new NameExtracted
                {
                    NameTypeCode = "same same"
                };

                var names = new[]
                {
                    _nameScenarioBuilder.Build(),
                    _nameScenarioBuilder.Build()
                };

                var subject = new NamesMapper();
                var r = subject.ExtractSources(names);

                Assert.Single(r);
            }

            [Fact]
            public void DoesNotReturnDuplicateNameTypeCodeForMapping()
            {
                _nameScenarioBuilder.Name = new NameExtracted
                {
                    CountryCode = "same same"
                };

                var names = new[]
                {
                    _nameScenarioBuilder.Build(),
                    _nameScenarioBuilder.Build()
                };

                var subject = new NamesMapper();
                var r = subject.ExtractSources(names);

                Assert.Single(r);
            }

            [Fact]
            public void IgnoreThoseWithoutAnythingForMapping()
            {
                _nameScenarioBuilder.Name = new NameExtracted
                {
                    NameTypeCode = null,
                    CountryCode = null
                };

                var names = new[]
                {
                    _nameScenarioBuilder.Build()
                };

                var subject = new NamesMapper();
                var r = subject.ExtractSources(names);

                Assert.Empty(r);
            }

            [Fact]
            public void ReturnsCountryCodeForMapping()
            {
                _nameScenarioBuilder.Name = new NameExtracted
                {
                    CountryCode = "RU"
                };

                var names = new[]
                {
                    _nameScenarioBuilder.Build()
                };

                var subject = new NamesMapper();
                var r = subject.ExtractSources(names).Single();

                Assert.Equal(KnownMapStructures.Country, r.TypeId);
                Assert.Equal("RU", r.Code);
                Assert.Null(r.Description);
            }

            [Fact]
            public void ReturnsNameTypeForMapping()
            {
                _nameScenarioBuilder.Name = new NameExtracted
                {
                    NameTypeCode = "Applicant"
                };

                var names = new[]
                {
                    _nameScenarioBuilder.Build()
                };

                var subject = new NamesMapper();
                var r = subject.ExtractSources(names).Single();

                Assert.Equal(KnownMapStructures.NameType, r.TypeId);
                Assert.Equal("Applicant", r.Description);
                Assert.Null(r.Code);
            }
        }

        public class ApplyMappingMethod
        {
            const string NameTypeExtracted = "Inventor";
            const string NameTypeMapped = "J";

            const string CountryExtracted = "Singapore";
            const string CountryMapped = "SG";

            readonly NameExtracted _name = new NameExtracted();
            readonly NameComparisonScenarioBuilder _nameScenarioBuilder = new NameComparisonScenarioBuilder();

            [Fact]
            public void AppliesMappedCountryCodeToName()
            {
                _nameScenarioBuilder.Name = _name;
                _name.CountryCode = CountryExtracted;

                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Country, CountryMapped, CountryExtracted)
                                  .Build();

                var subject = new NamesMapper();
                var r = (ComparisonScenario<NameExtracted>)
                    subject.ApplyMapping(
                                         _nameScenarioBuilder.Build(), new[] {mappedValue});

                Assert.Equal(CountryMapped, r.Mapped.CountryCode);
            }

            [Fact]
            public void AppliesMappedNameTypeCodeToName()
            {
                _nameScenarioBuilder.Name = _name;
                _name.NameTypeCode = NameTypeExtracted;

                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.NameType, NameTypeMapped, null, NameTypeExtracted)
                                  .Build();

                var subject = new NamesMapper();
                var r = (ComparisonScenario<NameExtracted>)
                    subject.ApplyMapping(
                                         _nameScenarioBuilder.Build(), new[] {mappedValue});

                Assert.Equal(NameTypeMapped, r.Mapped.NameTypeCode);
            }

            [Fact]
            public void IgnoresWhenMappedValuesNotFound()
            {
                _nameScenarioBuilder.Name = new NameExtracted();

                var subject = new NamesMapper();
                var r = (ComparisonScenario<NameExtracted>)
                    subject.ApplyMapping(_nameScenarioBuilder.Build(), Enumerable.Empty<MappedValue>());

                Assert.Null(r.Mapped.CountryCode);
                Assert.Null(r.Mapped.NameTypeCode);
            }

            [Fact]
            public void IgnoresWhenMappedValuesOutputIsEmpty()
            {
                _nameScenarioBuilder.Name = new NameExtracted
                {
                    CountryCode = "SG"
                };

                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Country, null, null, "SG")
                                  .Build();

                var subject = new NamesMapper();
                var r = (ComparisonScenario<NameExtracted>)
                    subject.ApplyMapping(
                                         _nameScenarioBuilder.Build(), new[] {mappedValue});

                Assert.Equal("SG", r.Mapped.CountryCode);
            }
        }
    }
}