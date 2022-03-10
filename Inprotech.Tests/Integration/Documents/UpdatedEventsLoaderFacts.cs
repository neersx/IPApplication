using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.AutomaticDocketing;
using Inprotech.Integration.Documents;
using InprotechKaizen.Model.Components.Cases.Events;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Documents
{
    public class UpdatedEventsLoaderFacts
    {
        public class LoadMethod
        {
            [Fact]
            public void CyclesForCyclicEventIsReturnedAccordingly()
            {
                var doc1 = new Document
                {
                    DocumentEvent = new DocumentEvent
                    {
                        CorrelationId = 333,
                        CorrelationEventId = 222,
                        CorrelationCycle = 5
                    }
                };

                var f = new UpdatedEventsLoaderFixture()
                        .WithResolvedEvent(new ResolvedEvent(222, "specific description", true))
                        .Configure();

                var r = f.Subject.Load(333, new[] {doc1});

                Assert.Equal(5, r[doc1].Cycle);
                Assert.True(r[doc1].IsCyclic);
            }

            [Fact]
            public void ReturnsUpdatedEventObjectForEachDocument()
            {
                var doc1 = new Document();
                var doc2 = new Document();

                var f = new UpdatedEventsLoaderFixture()
                    .Configure();

                var r = f.Subject.Load(null, new[] {doc1, doc2});

                Assert.NotNull(r[doc1]);
                Assert.NotNull(r[doc2]);
            }

            [Fact]
            public void ReturnsUpdatedEventReferedByDocument()
            {
                var doc1 = new Document
                {
                    DocumentEvent = new DocumentEvent
                    {
                        CorrelationId = 333,
                        CorrelationEventId = 222,
                        CorrelationCycle = 1
                    }
                };

                var f = new UpdatedEventsLoaderFixture()
                        .WithResolvedEvent(new ResolvedEvent(222, "specific description", false))
                        .Configure();

                var r = f.Subject.Load(333, new[] {doc1});

                Assert.Equal("specific description", r[doc1].Description);
                Assert.Equal(1, r[doc1].Cycle);
                Assert.False(r[doc1].IsCyclic);
            }
        }

        public class UpdatedEventsLoaderFixture : IFixture<UpdatedEventsLoader>
        {
            readonly List<ResolvedEvent> _resolvedEvents = new List<ResolvedEvent>();

            public UpdatedEventsLoaderFixture()
            {
                ValidEventsResolver = Substitute.For<IValidEventsResolver>();

                Subject = new UpdatedEventsLoader(ValidEventsResolver);
            }

            public IValidEventsResolver ValidEventsResolver { get; set; }

            public UpdatedEventsLoader Subject { get; set; }

            public UpdatedEventsLoaderFixture WithResolvedEvent(params ResolvedEvent[] resolvedEvents)
            {
                _resolvedEvents.AddRange(resolvedEvents);
                return this;
            }

            public UpdatedEventsLoaderFixture Configure()
            {
                ValidEventsResolver.Resolve(Arg.Any<int>(), Arg.Any<IEnumerable<int>>())
                                   .Returns(
                                            x =>
                                            {
                                                var existing = _resolvedEvents.Select(_ => _.EventId);

                                                return
                                                    ((IEnumerable<int>) x[1])
                                                    .Where(_ => !existing.Contains(_))
                                                    .Select(
                                                            _ => new ResolvedEvent(_, null, false)
                                                           ).Union(_resolvedEvents);
                                            }
                                           );

                return this;
            }
        }
    }
}