using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.PtoAccess.DmsIntegration;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    public class DocumentStatusUpdaterFacts
    {
        public class UpdateToMethod : FactBase
        {
            public UpdateToMethod()
            {
                _doc = new Document
                {
                    Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                    ApplicationNumber = "app1",
                    DocumentObjectId = "doc1"
                }.In(Db);
            }

            readonly Document _doc;

            [Fact]
            public async Task ShouldNotSetIfStatusIsTheSame()
            {
                var fixture = new DocumentStatusUpdaterFixture(Db)
                    .AllowsAllStatus();

                _doc.Status = DocumentDownloadStatus.SentToDms;

                var result = await fixture.Subject.UpdateTo(_doc.Id, DocumentDownloadStatus.SentToDms);

                var docResult = Db.Set<Document>()
                                  .Single(
                                          d =>
                                              d.ApplicationNumber == _doc.ApplicationNumber && d.DocumentObjectId == _doc.DocumentObjectId);

                Assert.Equal(DocumentDownloadStatus.SentToDms, docResult.Status);
                Assert.False(result);
            }

            [Fact]
            public async Task ShouldNotSetIfStatusTransitionNotPermitted()
            {
                var fixture = new DocumentStatusUpdaterFixture(Db); /* CanChangeDmsStatus = false */

                var result = await fixture.Subject.UpdateTo(_doc.Id, DocumentDownloadStatus.SentToDms);

                var docResult = Db.Set<Document>()
                                  .Single(
                                          d =>
                                              d.ApplicationNumber == _doc.ApplicationNumber && d.DocumentObjectId == _doc.DocumentObjectId);

                Assert.Equal(DocumentDownloadStatus.ScheduledForSendingToDms, docResult.Status);
                Assert.False(result);
            }

            [Fact]
            public async Task ShouldPublishConcurrencyException()
            {
                var fixture = new DocumentStatusUpdaterFixture(Db);

                fixture
                    .CalculateDownloadStatus
                    .WhenForAnyArgs(
                                    x => x.CanChangeDmsStatus(Arg.Any<DocumentDownloadStatus>(), Arg.Any<DocumentDownloadStatus>()))
                    .Do(x =>
                    {
                        /* just hijacking this component to throw DBConrrencyException */
                        /* It should've have been thrown by SaveChanges */
                        throw new DBConcurrencyException("Bummer!!!");
                    });

                var result = await fixture.Subject.UpdateTo(_doc.Id, DocumentDownloadStatus.SentToDms);
                Assert.False(result);

                fixture.DmsIntegrationPublisher.Received(1).Publish(Arg.Any<DmsIntegrationFailedMessage>());
            }

            [Fact]
            public async Task ShouldSetDocumentStatus()
            {
                var fixture = new DocumentStatusUpdaterFixture(Db)
                    .AllowsAllStatus();

                var result = await fixture.Subject.UpdateTo(_doc.Id, DocumentDownloadStatus.SentToDms);

                var docResult = Db.Set<Document>()
                                  .Single(
                                          d =>
                                              d.ApplicationNumber == _doc.ApplicationNumber && d.DocumentObjectId == _doc.DocumentObjectId);

                Assert.Equal(DocumentDownloadStatus.SentToDms, docResult.Status);
                Assert.True(result);
            }
        }

        public class UpdateAllToMethod : FactBase
        {
            public UpdateAllToMethod()
            {
                _docs = new List<Document>
                {
                    new Document
                    {
                        Status = DocumentDownloadStatus.SendToDms,
                        ApplicationNumber = "app1",
                        DocumentObjectId = "doc1",
                        Id = 1
                    }.In(Db),
                    new Document
                    {
                        Status = DocumentDownloadStatus.SendToDms,
                        ApplicationNumber = "app2",
                        DocumentObjectId = "doc2",
                        Id = 2
                    }.In(Db)
                };
            }

            readonly List<Document> _docs;

            [Fact]
            public async Task ShouldSetAllDocumentsStatus()
            {
                var fixture = new DocumentStatusUpdaterFixture(Db)
                    .AllowsAllStatus();

                await fixture.Subject.UpdateAllTo(_docs.Select(d => d.Id), DocumentDownloadStatus.SentToDms);

                var allDocStatus = Db.Set<Document>()
                                     .Select(_ => _.Status)
                                     .Distinct();

                Assert.Equal(1, allDocStatus.Count());
                Assert.Equal(DocumentDownloadStatus.SentToDms, allDocStatus.Single());
            }
        }

        public class DocumentStatusUpdaterFixture : IFixture<DocumentStatusUpdater>
        {
            public DocumentStatusUpdaterFixture(InMemoryDbContext db)
            {
                CalculateDownloadStatus = Substitute.For<ICalculateDownloadStatus>();

                DmsIntegrationPublisher = Substitute.For<IDmsIntegrationPublisher>();

                Subject = new DocumentStatusUpdater(db, CalculateDownloadStatus,
                                                    DmsIntegrationPublisher);
            }

            public ICalculateDownloadStatus CalculateDownloadStatus { get; set; }

            public IDmsIntegrationPublisher DmsIntegrationPublisher { get; set; }

            public DocumentStatusUpdater Subject { get; set; }

            public DocumentStatusUpdaterFixture AllowsAllStatus()
            {
                CalculateDownloadStatus.CanChangeDmsStatus(Arg.Any<DocumentDownloadStatus>(),
                                                           Arg.Any<DocumentDownloadStatus>())
                                       .Returns(true);

                return this;
            }
        }
    }
}