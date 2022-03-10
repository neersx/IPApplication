using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Ede.DataMapping;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class MatchingNumberEventMapperFacts
    {
        public class ExtractSourcesMethod
        {
            readonly ICommonEventMapper _commonEventMapper = Substitute.For<ICommonEventMapper>();

            readonly MatchingNumberEventComparisonScenarioBuilder _eventScenarioBuilder = new MatchingNumberEventComparisonScenarioBuilder
            {
                Event = new MatchingNumberEvent()
            };

            [Fact]
            public void CallCommonEventMapperForMatchingNumberEvents()
            {
                var returnValues = new Source[0];

                _commonEventMapper.ExtractSources(Arg.Any<IEnumerable<IEvent>>())
                                  .Returns(returnValues);

                var scenario = _eventScenarioBuilder.Build();

                var subject = new MatchingNumberEventMapper(_commonEventMapper);

                var r = subject.ExtractSources(new[] {scenario}).ToArray();

                Assert.Equal(returnValues, r);

                _commonEventMapper.ExtractSources(Arg.Is<IEnumerable<IEvent>>(_ => _.Contains(scenario.ComparisonSource)));
            }

            [Fact]
            public void IgnoreOtherStructures()
            {
                var scenario = new EventComparisonScenarioBuilder
                {
                    Event = new Event()
                }.Build();

                var subject = new MatchingNumberEventMapper(_commonEventMapper);

                var _ = subject.ExtractSources(new[] {scenario}).ToArray();

                _commonEventMapper.ExtractSources(Enumerable.Empty<IEvent>());
            }
        }

        public class ApplyMappingMethod
        {
            readonly ICommonEventMapper _commonEventMapper = Substitute.For<ICommonEventMapper>();

            readonly MatchingNumberEventComparisonScenarioBuilder _eventScenarioBuilder = new MatchingNumberEventComparisonScenarioBuilder
            {
                Event = new MatchingNumberEvent()
            };

            [Fact]
            public void ApplyMappingIfApplicable()
            {
                _eventScenarioBuilder.Event = new MatchingNumberEvent();

                var mappedValue1 = new MappedValueBuilder()
                                   .For(KnownMapStructures.Events, Fixture.Integer().ToString())
                                   .Build();

                _commonEventMapper.TryResolveApplicableMapping(_eventScenarioBuilder.Event, Arg.Any<IEnumerable<MappedValue>>(), out var resultMappedValue)
                                  .Returns(x =>
                                  {
                                      x[2] = resultMappedValue = ((IEnumerable<MappedValue>) x[1]).Single();
                                      return true;
                                  });

                var subject = new MatchingNumberEventMapper(_commonEventMapper);

                var r = subject.ApplyMapping(_eventScenarioBuilder.Build(), new[] {mappedValue1});

                Assert.Equal(int.Parse(mappedValue1.Output),
                             ((ComparisonScenario<MatchingNumberEvent>) r).Mapped.Id);
            }

            [Fact]
            public void ReturnsWithoutMappingApplied()
            {
                _eventScenarioBuilder.Event = new MatchingNumberEvent();

                var mappedValue1 = new MappedValueBuilder
                                   {
                                       Output = Fixture.Integer().ToString()
                                   }
                                   .For(KnownMapStructures.Events)
                                   .Build();

                MappedValue resultMappedValue;
                _commonEventMapper.TryResolveApplicableMapping(_eventScenarioBuilder.Event, Arg.Any<IEnumerable<MappedValue>>(), out resultMappedValue)
                                  .Returns(x =>
                                  {
                                      x[2] = resultMappedValue = null;
                                      return false;
                                  });

                var subject = new MatchingNumberEventMapper(_commonEventMapper);

                var r = subject.ApplyMapping(_eventScenarioBuilder.Build(), new[] {mappedValue1});

                Assert.Null(((ComparisonScenario<MatchingNumberEvent>) r).Mapped.Id);
            }
        }
    }
}