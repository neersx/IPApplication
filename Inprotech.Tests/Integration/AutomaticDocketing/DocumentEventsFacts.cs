using System;
using System.Linq;
using Inprotech.Integration.AutomaticDocketing;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.AutomaticDocketing
{
    public class DocumentEventsFacts
    {
        public class UpdateAutomaticallyMethod : FactBase
        {
            [Fact]
            public void UpdatesEvents()
            {
                var documents = new[]
                {
                    new Document
                    {
                        Id = 1,
                        DocumentEvent = new DocumentEvent
                        {
                            DocumentId = 1,
                            Status = DocumentEventStatus.Pending
                        }
                    }
                };

                var f = new DocumentEventsFixture(Db)
                    .WithRelevantEvents(new Event
                    {
                        CorrelationRef = "1",
                        EventNo = 888,
                        Cycle = 1,
                        EventDate = new Value<DateTime?>
                        {
                            TheirValue = Fixture.Today(),
                            Updateable = true
                        }
                    });

                f.Subject.UpdateAutomatically("hello", 999, documents);

                f.RelevantEvents.Received(1).Resolve(Arg.Any<string>(), Arg.Any<int>(), Arg.Any<Document[]>());

                var d = documents.Single();

                Assert.Equal(DocumentEventStatus.Processed, d.DocumentEvent.Status);
                Assert.Equal(888, d.DocumentEvent.CorrelationEventId);
                Assert.Equal(1, d.DocumentEvent.CorrelationCycle);
                Assert.Equal(999, d.DocumentEvent.CorrelationId);
            }
        }

        public class DocumentEventsFixture : IFixture<DocumentEvents>
        {
            public DocumentEventsFixture(InMemoryDbContext db)
            {
                ApplyUpdates = Substitute.For<IApplyUpdates>();
                ApplyUpdates.From(Arg.Any<Event[]>(), Arg.Any<int>())
                            .Returns(x => x[0]);

                RelevantEvents = Substitute.For<IRelevantEvents>();

                Subject = new DocumentEvents(db, RelevantEvents, ApplyUpdates, Fixture.Today);
            }

            public IApplyUpdates ApplyUpdates { get; set; }

            public IRelevantEvents RelevantEvents { get; set; }

            public DocumentEvents Subject { get; set; }

            public DocumentEventsFixture WithRelevantEvents(params Event[] events)
            {
                RelevantEvents.Resolve(Arg.Any<string>(), Arg.Any<int>(), Arg.Any<Document[]>())
                              .Returns(events);

                return this;
            }
        }
    }
}