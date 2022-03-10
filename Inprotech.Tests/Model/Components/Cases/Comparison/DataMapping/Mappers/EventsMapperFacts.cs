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
    public class EventsMapperFacts
    {
        public class ExtractSourcesMethod
        {
            readonly ICommonEventMapper _commonEventMapper = Substitute.For<ICommonEventMapper>();

            readonly EventComparisonScenarioBuilder _eventScenarioBuilder = new EventComparisonScenarioBuilder
            {
                Event = new Event()
            };

            [Fact]
            public void CallCommonEventMapperForMatchingNumberEvents()
            {
                var returnValues = new Source[0];

                _commonEventMapper.ExtractSources(Arg.Any<IEnumerable<IEvent>>())
                                  .Returns(returnValues);

                var scenario = _eventScenarioBuilder.Build();

                var subject = new EventsMapper(_commonEventMapper);

                var r = subject.ExtractSources(new[] {scenario}).ToArray();

                Assert.Equal(returnValues, r);

                _commonEventMapper.ExtractSources(Arg.Is<IEnumerable<IEvent>>(_ => _.Contains(scenario.ComparisonSource)));
            }

            [Fact]
            public void IgnoreOtherStructures()
            {
                var scenario = new MatchingNumberEventComparisonScenarioBuilder
                {
                    Event = new MatchingNumberEvent()
                }.Build();

                var subject = new EventsMapper(_commonEventMapper);

                var _ = subject.ExtractSources(new[] {scenario}).ToArray();

                _commonEventMapper.ExtractSources(Enumerable.Empty<IEvent>());
            }
        }

        public class ApplyMappingMethod
        {
            readonly ICommonEventMapper _commonEventMapper = Substitute.For<ICommonEventMapper>();

            readonly EventComparisonScenarioBuilder _eventScenarioBuilder = new EventComparisonScenarioBuilder
            {
                Event = new Event()
            };

            [Fact]
            public void ApplyMappingIfApplicable()
            {
                _eventScenarioBuilder.Event = new Event();

                var mappedValue1 = new MappedValueBuilder()
                                   .For(KnownMapStructures.Events, Fixture.Integer().ToString())
                                   .Build();

                _commonEventMapper.TryResolveApplicableMapping(_eventScenarioBuilder.Event, Arg.Any<IEnumerable<MappedValue>>(), out var resultMappedValue)
                                  .Returns(x =>
                                  {
                                      x[2] = resultMappedValue = ((IEnumerable<MappedValue>) x[1]).Single();
                                      return true;
                                  });

                var subject = new EventsMapper(_commonEventMapper);

                var r = subject.ApplyMapping(_eventScenarioBuilder.Build(), new[] {mappedValue1});

                Assert.Equal(int.Parse(mappedValue1.Output),
                             ((ComparisonScenario<Event>) r).Mapped.Id);
            }

            [Fact]
            public void ReturnsWithoutMappingApplied()
            {
                _eventScenarioBuilder.Event = new Event();

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

                var subject = new EventsMapper(_commonEventMapper);

                var r = subject.ApplyMapping(_eventScenarioBuilder.Build(), new[] {mappedValue1});

                Assert.Null(((ComparisonScenario<Event>) r).Mapped.Id);
            }
        }
    }
}