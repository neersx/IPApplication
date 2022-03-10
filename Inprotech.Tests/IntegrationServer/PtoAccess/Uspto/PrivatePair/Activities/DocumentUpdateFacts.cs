using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class DocumentUpdateFacts
    {
        public class ApplyMethod : FactBase
        {
            readonly ApplicationDownload _application = new ApplicationDownload
            {
                SessionName = "Blah",
                Number = "PCT1234",
                CustomerNumber = "70859"
            };

            [Theory]
            [InlineData(DocumentDownloadStatus.Pending)]
            [InlineData(DocumentDownloadStatus.Failed)]
            public async Task UpdatesExistingUsptoDocument(DocumentDownloadStatus status)
            {
                var f = new DocumentUpdateFixture(Db);

                CreateDocument(status);

                var documentDownloaded = BuildDocumentDownloaded();

                f.DownloadStatusCalculator.GetDownloadStatus(DataSourceType.UsptoPrivatePair)
                 .Returns(DocumentDownloadStatus.Downloaded);

                f.ArtifactsLocationResolver.ResolveFiles(_application, documentDownloaded.FileNameObjectId + ".pdf")
                 .Returns("document filenpath relative to application");

                await f.Subject.Apply(new Session(), _application, documentDownloaded);

                var persisted = Db.Set<Document>()
                                  .SingleOrDefault(d => d.DocumentCategory == documentDownloaded.DocumentCategory &&
                                                        d.DocumentDescription == documentDownloaded.DocumentDescription &&
                                                        d.DocumentObjectId == documentDownloaded.ObjectId &&
                                                        d.FileWrapperDocumentCode == documentDownloaded.FileWrapperDocumentCode &&
                                                        d.PageCount == documentDownloaded.PageCount &&
                                                        d.MailRoomDate == documentDownloaded.MailRoomDate);

                Assert.NotNull(persisted);

                Assert.Equal("document filenpath relative to application", persisted.FileStore.Path);
                Assert.Equal(persisted.FileStore.OriginalFileName, documentDownloaded.FileNameObjectId + ".pdf");

                Assert.False(Path.IsPathRooted(persisted.FileStore.Path));

                Assert.Equal(DocumentDownloadStatus.Downloaded, persisted.Status);
                Assert.Null(persisted.Errors);
            }

            [Theory]
            [InlineData(DocumentDownloadStatus.SentToDms)]
            [InlineData(DocumentDownloadStatus.ScheduledForSendingToDms)]
            [InlineData(DocumentDownloadStatus.FailedToSendToDms)]
            [InlineData(DocumentDownloadStatus.SendingToDms)]
            public async Task WillNotReverseStatusOfExistingDocument(DocumentDownloadStatus status)
            {
                var f = new DocumentUpdateFixture(Db);

                CreateDocument(status);

                var documentDownloaded = BuildDocumentDownloaded();

                f.ArtifactsLocationResolver.ResolveFiles(_application, documentDownloaded.FileNameObjectId + ".pdf")
                 .Returns("document filenpath relative to application");

                await f.Subject.Apply(new Session(), _application, documentDownloaded);

                /* if a document has already progressed to DMS integration phase, it should not be set to a status that reverses workflow */
                /* i.e. same document will not end up in dms integration folder */
                Assert.Equal(status, Db.Set<Document>().Single().Status);

                f.DownloadStatusCalculator.DidNotReceive().GetDownloadStatus(Arg.Any<DataSourceType>());
            }

            static AvailableDocument BuildDocumentDownloaded()
            {
                var documentDownloaded = new AvailableDocument
                {
                    DocumentCategory = Fixture.String(),
                    DocumentDescription = Fixture.String(),
                    FileWrapperDocumentCode = Fixture.String(),
                    MailRoomDate = Fixture.Today(),
                    ObjectId = "1234567",
                    FileNameObjectId = "1234567",
                    PageCount = Fixture.Integer()
                };
                return documentDownloaded;
            }

            Document CreateDocument(DocumentDownloadStatus status)
            {
                return new Document
                {
                    ApplicationNumber = _application.Number,
                    DocumentObjectId = "1234567",
                    Status = status,
                    FileStore = new FileStore
                    {
                        OriginalFileName = "blah blah blah",
                        Path = "random location"
                    }.In(Db)
                }.In(Db);
            }

            [Fact]
            public async Task CreatesUsptoDocumentIfNotExists()
            {
                var f = new DocumentUpdateFixture(Db);

                var documentDownloaded = BuildDocumentDownloaded();

                f.ArtifactsLocationResolver.ResolveFiles(_application, documentDownloaded.FileNameObjectId + ".pdf")
                 .Returns("document filenpath relative to application");

                f.DownloadStatusCalculator.GetDownloadStatus(DataSourceType.UsptoPrivatePair)
                 .Returns(DocumentDownloadStatus.Downloaded);

                await f.Subject.Apply(new Session(), _application, documentDownloaded);

                var persisted = Db.Set<Document>()
                                  .SingleOrDefault(d => d.DocumentCategory == documentDownloaded.DocumentCategory &&
                                                        d.DocumentDescription == documentDownloaded.DocumentDescription &&
                                                        d.DocumentObjectId == documentDownloaded.ObjectId &&
                                                        d.FileWrapperDocumentCode == documentDownloaded.FileWrapperDocumentCode &&
                                                        d.PageCount == documentDownloaded.PageCount &&
                                                        d.MailRoomDate == documentDownloaded.MailRoomDate);

                Assert.NotNull(persisted);

                Assert.Equal("document filenpath relative to application", persisted.FileStore.Path);
                Assert.Equal(persisted.FileStore.OriginalFileName, documentDownloaded.FileNameObjectId + ".pdf");

                Assert.False(Path.IsPathRooted(persisted.FileStore.Path));

                Assert.Equal(DocumentDownloadStatus.Downloaded, persisted.Status);
                Assert.Null(persisted.Errors);
            }

            [Fact]
            public async Task NotifiesScheduleRuntime()
            {
                var f = new DocumentUpdateFixture(Db);

                await f.Subject.Apply(new Session(), _application, BuildDocumentDownloaded());

                f.ScheduleRuntimeEvents.Received(1).DocumentProcessed(Arg.Any<Guid>(), Arg.Any<Document>());
            }
        }

        public class DocumentUpdateFixture : IFixture<IDocumentUpdate>
        {
            public DocumentUpdateFixture(InMemoryDbContext db)
            {
                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();

                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

                DownloadStatusCalculator = Substitute.For<ICalculateDownloadStatus>();

                Subject = new DocumentUpdate(db, ArtifactsLocationResolver, Fixture.Today,
                                             ScheduleRuntimeEvents, DownloadStatusCalculator);
            }

            public IArtifactsLocationResolver ArtifactsLocationResolver { get; set; }

            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }

            public ICalculateDownloadStatus DownloadStatusCalculator { get; set; }

            public IDocumentUpdate Subject { get; }
        }
    }
}