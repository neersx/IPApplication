using System.Linq;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Ede.DataMapping;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class CommonEventsMapperFacts
    {
        public class ExtractSourcesMethod
        {
            [Fact]
            public void DoesNotReturnDuplicatesForCode()
            {
                var events = new[]
                {
                    new Event
                    {
                        EventCode = "same same"
                    },
                    new Event
                    {
                        EventCode = "same same"
                    }
                };

                var subject = new CommonEventMapper();
                var r = subject.ExtractSources(events);

                Assert.Single(r);
            }

            [Fact]
            public void DoesNotReturnDuplicatesForDescriptions()
            {
                var events = new[]
                {
                    new Event
                    {
                        EventDescription = "same same"
                    },
                    new Event
                    {
                        EventDescription = "same same"
                    }
                };

                var subject = new CommonEventMapper();
                var r = subject.ExtractSources(events);

                Assert.Single(r);
            }

            [Fact]
            public void ReturnsEventsWithCodeWhenDescriptionIsBlank()
            {
                var events = new[]
                {
                    new Event
                    {
                        EventCode = "world"
                    }
                };

                var subject = new CommonEventMapper();
                var r = subject.ExtractSources(events).Single();

                Assert.Equal(KnownMapStructures.Events, r.TypeId);
                Assert.Equal("world", r.Code);
                Assert.Null(r.Description);
            }

            [Fact]
            public void ReturnsOnlyEventsDescriptionsForMapping()
            {
                var events = new[]
                {
                    new Event
                    {
                        EventDescription = "hello",
                        EventCode = "world"
                    }
                };

                var subject = new CommonEventMapper();
                var r = subject.ExtractSources(events).Single();

                Assert.Equal(KnownMapStructures.Events, r.TypeId);
                Assert.Equal("hello", r.Description);
                Assert.Null(r.Code);
            }
        }

        public class TryResolveApplicableMappingMethod
        {
            const string Evt = "Filing Receipt Received";
            const string Code = "Filling";

            readonly Event _eventWithDescription = new Event
            {
                EventDescription = Evt,
                EventCode = Code
            };

            readonly Event _eventWithCode = new Event
            {
                EventCode = Code
            };

            [Fact]
            public void AppliesMappedValueToEventWithCode()
            {
                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Events, "-999", null, Code)
                                  .Build();

                var subject = new CommonEventMapper();
                var r = subject.TryResolveApplicableMapping(_eventWithCode, new[] {mappedValue}, out var resultMappedValue);

                Assert.Equal(mappedValue, resultMappedValue);
                Assert.True(r);
            }

            [Fact]
            public void AppliesMappedValueToEventWithCodeWithMappedCode()
            {
                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Events, "-999", Code)
                                  .Build();

                var subject = new CommonEventMapper();
                var r = subject.TryResolveApplicableMapping(_eventWithCode, new[] {mappedValue}, out var resultMappedValue);

                Assert.Equal(mappedValue, resultMappedValue);
                Assert.True(r);
            }

            [Fact]
            public void AppliesMappedValueToEventWithDescription()
            {
                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Events, "-999", null, Evt)
                                  .Build();

                var subject = new CommonEventMapper();
                var r = subject.TryResolveApplicableMapping(_eventWithDescription, new[] {mappedValue}, out var resultMappedValue);

                Assert.Equal(mappedValue, resultMappedValue);
                Assert.True(r);
            }

            [Fact]
            public void IgnoresMappedValuesForOtherStructures()
            {
                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Country, "-999", null, Evt)
                                  .Build();

                var subject = new CommonEventMapper();
                var r = subject.TryResolveApplicableMapping(_eventWithDescription, new[] {mappedValue}, out var resultMappedValue);

                Assert.Null(resultMappedValue);
                Assert.False(r);
            }

            [Fact]
            public void IgnoresWhenMappedValuesNotFound()
            {
                var subject = new CommonEventMapper();
                var r = subject.TryResolveApplicableMapping(_eventWithDescription, Enumerable.Empty<MappedValue>(), out var resultMappedValue);

                Assert.Null(resultMappedValue);
                Assert.False(r);
            }

            [Fact]
            public void IgnoresWhenMappedValuesOutputIsEmpty()
            {
                var mappedValue = new MappedValueBuilder()
                                  .For(KnownMapStructures.Events, null, null, Evt)
                                  .Build();

                var subject = new CommonEventMapper();
                var r = subject.TryResolveApplicableMapping(_eventWithDescription, new[] {mappedValue}, out var resultMappedValue);

                Assert.Null(resultMappedValue);
                Assert.False(r);
            }
        }
    }
}