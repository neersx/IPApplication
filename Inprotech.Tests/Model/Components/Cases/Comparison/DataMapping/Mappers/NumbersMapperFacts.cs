using System.Linq;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Ede.DataMapping;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class NumbersMapperFacts
    {
        public class ExtractSourcesMethod
        {
            readonly OfficialNumberComparisonScenarioBuilder _numberScenarioBuilder = new OfficialNumberComparisonScenarioBuilder();

            [Fact]
            public void DoesNotReturnDuplicates()
            {
                _numberScenarioBuilder.OfficialNumber = new OfficialNumber
                {
                    NumberType = "same same"
                };

                var numbers = new[]
                {
                    _numberScenarioBuilder.Build(),
                    _numberScenarioBuilder.Build()
                };

                var subject = new NumbersMapper();
                var r = subject.ExtractSources(numbers);

                Assert.Single(r);
            }

            [Fact]
            public void ReturnsOnlyEventsDescriptionsForMapping()
            {
                _numberScenarioBuilder.OfficialNumber = new OfficialNumber
                {
                    Number = "PCT/2001/1234",
                    NumberType = "Application"
                };

                var numbers = new[]
                {
                    _numberScenarioBuilder.Build()
                };

                var subject = new NumbersMapper();
                var r = subject.ExtractSources(numbers).Single();

                Assert.Equal(KnownMapStructures.NumberType, r.TypeId);
                Assert.Equal("Application", r.Code);
                Assert.Null(r.Description);
            }
        }

        public class ApplyMappingMethod
        {
            const string Publication = "Publication";

            readonly OfficialNumber _number = new OfficialNumber
            {
                NumberType = Publication
            };

            readonly OfficialNumberComparisonScenarioBuilder _numberScenarioBuilder = new OfficialNumberComparisonScenarioBuilder();

            [Fact]
            public void AppliesMappedValueToEvent()
            {
                _numberScenarioBuilder.OfficialNumber = _number;

                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.NumberType, "P", Publication)
                                  .Build();

                var subject = new NumbersMapper();
                var r = (ComparisonScenario<OfficialNumber>)
                    subject.ApplyMapping(
                                         _numberScenarioBuilder.Build(), new[] {mappedValue});

                Assert.Equal("P", r.Mapped.NumberType);
            }

            [Fact]
            public void IgnoresMappedValuesForOtherStructures()
            {
                _numberScenarioBuilder.OfficialNumber = _number;

                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Country, "-999", null, Publication)
                                  .Build();

                var subject = new NumbersMapper();
                var r = (ComparisonScenario<OfficialNumber>)
                    subject.ApplyMapping(
                                         _numberScenarioBuilder.Build(), new[] {mappedValue});

                Assert.Equal(r.ComparisonSource.NumberType, r.Mapped.NumberType);
            }

            [Fact]
            public void IgnoresWhenMappedValuesNotFound()
            {
                _numberScenarioBuilder.OfficialNumber = _number;

                var subject = new NumbersMapper();
                var r = (ComparisonScenario<OfficialNumber>)
                    subject.ApplyMapping(_numberScenarioBuilder.Build(), Enumerable.Empty<MappedValue>());

                Assert.Equal(r.ComparisonSource.NumberType, r.Mapped.NumberType);
            }

            [Fact]
            public void IgnoresWhenMappedValuesOutputIsEmpty()
            {
                _numberScenarioBuilder.OfficialNumber = _number;

                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.NumberType, null, null, Publication)
                                  .Build();

                var subject = new NumbersMapper();
                var r = (ComparisonScenario<OfficialNumber>)
                    subject.ApplyMapping(_numberScenarioBuilder.Build(), new[] {mappedValue});

                Assert.Equal(r.ComparisonSource.NumberType, r.Mapped.NumberType);
            }
        }
    }
}