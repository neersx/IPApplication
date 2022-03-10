using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.Documents
{
    public class DocumentsControllerFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void IndicatesImportedDocument()
            {
                var attachmentReference = Guid.NewGuid();

                var doc = new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Downloaded,
                    ApplicationNumber = "1234",
                    Reference = attachmentReference
                };

                var result =
                    new DocumentsControllerFixture(Db).WithDocuments(doc)
                                                      .WithCase()
                                                      .WithImportedReference(attachmentReference)
                                                      .Subject.Get(DataSourceType.UsptoPrivatePair, 1);

                Assert.Single((IEnumerable<object>) result);
                Assert.True(((IEnumerable<dynamic>) result).First().Imported);
            }

            [Fact]
            public void ReturnsErrors()
            {
                var error = "e";

                var attachmentReference = Guid.NewGuid();

                var doc = new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Failed,
                    Errors = JsonConvert.SerializeObject(error),
                    Reference = attachmentReference
                };

                var result =
                    new DocumentsControllerFixture(Db).WithDocuments(doc)
                                                      .WithCase()
                                                      .Subject.Get(DataSourceType.UsptoPrivatePair, 1);

                Assert.Equal(error, ((IEnumerable<dynamic>) result).First().Errors);
            }

            [Fact]
            public void ReturnsUpdatedEvent()
            {
                var doc = new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Downloaded,
                    ApplicationNumber = "1234"
                };

                var result = new DocumentsControllerFixture(Db)
                             .WithUpdatedEvent(doc, new UpdatedEvent
                             {
                                 Cycle = 4,
                                 Description = "hello",
                                 IsCyclic = true
                             })
                             .WithDocuments(doc)
                             .WithCase()
                             .Subject.Get(DataSourceType.UsptoPrivatePair, 1);

                var r = ((IEnumerable<dynamic>) result).ToArray();

                Assert.Equal("hello", r[0].EventUpdatedDescription);
                Assert.Equal(4, r[0].EventUpdatedCycle);
            }

            [Fact]
            public void ReturnsUpdatedEventWithCycleSuppressed()
            {
                var doc = new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = DocumentDownloadStatus.Downloaded,
                    ApplicationNumber = "1234"
                };

                var result = new DocumentsControllerFixture(Db)
                             .WithUpdatedEvent(doc, new UpdatedEvent
                             {
                                 Cycle = 1,
                                 Description = "hello",
                                 IsCyclic = false
                             })
                             .WithDocuments(doc)
                             .WithCase()
                             .Subject.Get(DataSourceType.UsptoPrivatePair, 1);

                var r = ((IEnumerable<dynamic>) result).ToArray();

                Assert.Equal("hello", r[0].EventUpdatedDescription);
                Assert.Null(r[0].EventUpdatedCycle);
            }

            [Fact]
            public void ThrowsExceptionIfCaseIdNull()
            {
                var e =
                    Record.Exception(
                                     () => { new DocumentsControllerFixture(Db).Subject.Get(DataSourceType.UsptoPrivatePair, null); });

                Assert.IsType<ArgumentNullException>(e);
            }
        }

        public class DocumentsControllerFixture : IFixture<DocumentsController>
        {
            readonly InMemoryDbContext _db;
            readonly Dictionary<Document, UpdatedEvent> _updatedEvents = new Dictionary<Document, UpdatedEvent>();

            public DocumentsControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                UpdatedEventsLoader = Substitute.For<IUpdatedEventsLoader>();
                UpdatedEventsLoader
                    .Load(Arg.Any<int?>(), Arg.Any<IEnumerable<Document>>())
                    .ReturnsForAnyArgs(x =>

                                       {
                                           var r = ((IEnumerable<Document>) x[1]).ToDictionary(k => k,
                                                                                               v => new UpdatedEvent());

                                           foreach (var u in _updatedEvents)
                                           {
                                               if (!r.TryGetValue(u.Key, out var value)) continue;
                                               value.Cycle = u.Value.Cycle;
                                               value.Description = u.Value.Description;
                                               value.IsCyclic = u.Value.IsCyclic;
                                           }

                                           return r;
                                       }
                                      );

                DocumentLoader = Substitute.For<IDocumentLoader>();

                Subject = new DocumentsController(DocumentLoader, UpdatedEventsLoader);
            }

            public IUpdatedEventsLoader UpdatedEventsLoader { get; }

            public IDocumentLoader DocumentLoader { get; }

            public DocumentsController Subject { get; }

            public DocumentsControllerFixture WithUpdatedEvent(Document document, UpdatedEvent updatedEvent)
            {
                _updatedEvents[document] = updatedEvent;

                return this;
            }

            public DocumentsControllerFixture WithDocuments(Document doc)
            {
                DocumentLoader.GetDocumentsFrom(new DataSourceType(), null).ReturnsForAnyArgs(new[] {doc});

                return this;
            }

            public DocumentsControllerFixture WithImportedReference(Guid? referenceGuid)
            {
                DocumentLoader.GetImportedRefs(null).ReturnsForAnyArgs(new[] {referenceGuid});

                return this;
            }

            public DocumentsControllerFixture WithCase()
            {
                new Case(
                         "1",
                         new Country("1", "us").In(_db),
                         new CaseType("1", "t").In(_db),
                         new PropertyType("1", "p").In(_db)).In(_db);

                return this;
            }
        }
    }
}