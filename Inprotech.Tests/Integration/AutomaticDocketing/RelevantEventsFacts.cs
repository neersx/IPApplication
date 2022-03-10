using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.AutomaticDocketing;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using Event = InprotechKaizen.Model.Components.Cases.Comparison.Models.Event;

namespace Inprotech.Tests.Integration.AutomaticDocketing
{
    public class RelevantEventsFacts
    {
        public class ResolveMethod : FactBase
        {
            [Fact]
            public void BuildsComparisonScenarioForMappingResolutions()
            {
                var docs = new[]
                {
                    new Document {Id = 1, DocumentDescription = "123"},
                    new Document {Id = 2, DocumentDescription = "234"},
                    new Document {Id = 3, DocumentDescription = "456"}
                };

                var f = new RelevantEventsFixture(Db);

                f.Subject.Resolve("hello", 1, docs);

                f.DocumentMappings.Received(1).Resolve(
                                                       Arg.Is<IEnumerable<ComparisonScenario<Event>>>(
                                                                                                      x => x.Select(_ => _.ComparisonSource.EventDescription)
                                                                                                            .SequenceEqual(new[] {"123", "234", "456"})
                                                                                                     ), "hello");
            }

            [Fact]
            public void ReturnsEventsFromComparisonResult()
            {
                var docs = new[]
                {
                    new Document {Id = 1, DocumentDescription = "123"}
                };

                var f = new RelevantEventsFixture(Db);

                var events = new[]
                {
                    new InprotechKaizen.Model.Components.Cases.Comparison.Results.Event()
                };

                f.EventComparer.When(
                                     x =>
                                         x.Compare(Arg.Any<Case>(), Arg.Any<IEnumerable<ComparisonScenario>>(),
                                                   Arg.Any<ComparisonResult>()))
                 .Do(
                     x =>
                     {
                         var s = (ComparisonResult) x[2];
                         s.Events = events;
                     }
                    );

                var r = f.Subject.Resolve("hello", 1, docs);

                Assert.Equal(r, events);
            }

            [Fact]
            public void SendMapScenariosForEventsComparison()
            {
                var docs = new[]
                {
                    new Document {Id = 1, DocumentDescription = "123"}
                };

                var f = new RelevantEventsFixture(Db);

                f.Subject.Resolve("hello", 1, docs);

                f.EventComparer.Received(1)
                 .Compare(Arg.Any<Case>(), Arg.Any<IEnumerable<ComparisonScenario>>(), Arg.Any<ComparisonResult>());
            }
        }

        public class RelevantEventsFixture : IFixture<RelevantEvents>
        {
            public RelevantEventsFixture(InMemoryDbContext db)
            {
                new CaseBuilder().Build().In(db);

                DocumentMappings = Substitute.For<IDocumentMappings>();
                DocumentMappings.Resolve(Arg.Any<IEnumerable<ComparisonScenario<Event>>>(), Arg.Any<string>())
                                .Returns(x =>
                                {
                                    var i = 1;
                                    var events = ((IEnumerable<ComparisonScenario<Event>>) x[0]).ToArray();
                                    foreach (var e in events)
                                        e.Mapped.Id = i++;

                                    return events;
                                });

                EventComparer = Substitute.For<IEventsComparer>();

                Subject = new RelevantEvents(db, DocumentMappings, EventComparer);
            }

            public IDocumentMappings DocumentMappings { get; set; }

            public IEventsComparer EventComparer { get; set; }

            public RelevantEvents Subject { get; set; }
        }
    }
}