using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

#pragma warning disable 4014

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Activities
{
    public class PtoDocumentFacts
    {
        public class DownloadMethod : FactBase
        {
            readonly DataDownload _dataDownload = new DataDownload
            {
                Case =
                    new EligibleCase
                    {
                        ApplicationNumber = "app",
                        RegistrationNumber = "reg",
                        PublicationNumber = "pub",
                        CaseKey = 999
                    },
                DataSourceType = DataSourceType.UsptoTsdr
            };

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.Epo)]
            public async Task SavesDataSourceType(DataSourceType source)
            {
                var f = new DownloadDocumentFixture(Db);

                f.DataDownloadLocationResolver.Resolve(null).ReturnsForAnyArgs("MyPath");
                var dataDownload = new DataDownload
                {
                    Case =
                        new EligibleCase
                        {
                            ApplicationNumber = "app",
                            RegistrationNumber = "reg",
                            CaseKey = 999
                        },
                    DataSourceType = source
                };
                var doc = new Document
                {
                    ApplicationNumber = "app",
                    RegistrationNumber = "reg",
                    DocumentObjectId = "ObjId",
                    DocumentDescription = Fixture.String(),
                    DocumentCategory = Fixture.String(),
                    PageCount = Fixture.Integer(),
                    MailRoomDate = Fixture.PastDate()
                };
                await f.Subject.Download(dataDownload, doc, f.DocumentDownloadClient.Download);

                var document = Db.Set<Document>().First();

                Assert.Equal(source, document.Source);
            }

            [Theory]
            [InlineData(DocumentDownloadStatus.SentToDms)]
            [InlineData(DocumentDownloadStatus.ScheduledForSendingToDms)]
            [InlineData(DocumentDownloadStatus.FailedToSendToDms)]
            [InlineData(DocumentDownloadStatus.SendingToDms)]
            public async Task WillNotReverseStatusOfExistingDocument(DocumentDownloadStatus status)
            {
                var f = new DownloadDocumentFixture(Db);

                f.DataDownloadLocationResolver.Resolve(null).ReturnsForAnyArgs("MyPath");
                var dataDownload = new DataDownload
                {
                    Case =
                        new EligibleCase
                        {
                            ApplicationNumber = "app",
                            RegistrationNumber = "reg",
                            CaseKey = 999
                        },
                    DataSourceType = DataSourceType.UsptoTsdr
                };

                var doc = new Document
                {
                    ApplicationNumber = "app",
                    RegistrationNumber = "reg",
                    DocumentObjectId = "ObjId",
                    DocumentDescription = Fixture.String(),
                    DocumentCategory = Fixture.String(),
                    PageCount = Fixture.Integer(),
                    MailRoomDate = Fixture.PastDate(),
                    Status = status
                }.In(Db);

                await f.Subject.Download(dataDownload, doc, f.DocumentDownloadClient.Download);

                var document = Db.Set<Document>().First();

                Assert.Equal(status, document.Status);
            }

            [Fact]
            public async Task DownloadsAndStoresDocuments()
            {
                var f = new DownloadDocumentFixture(Db);

                f.DataDownloadLocationResolver.Resolve(null).ReturnsForAnyArgs("MyPath");

                var doc = new Document
                {
                    ApplicationNumber = "app",
                    Source = DataSourceType.UsptoTsdr,
                    DocumentObjectId = "ObjId",
                    DocumentDescription = "b",
                    MediaType = "abc",
                    SourceUrl = "http://somewhere"
                };
                await f.Subject.Download(_dataDownload, doc, f.DocumentDownloadClient.Download);

                f.DocumentDownloadClient.Received(1).Download("app", "ObjId", "b", "abc", "http://somewhere","MyPath");
            }

            [Fact]
            public async Task DownloadsAndStoresDocumentsForExistingErrorDocuments()
            {
                var f = new DownloadDocumentFixture(Db)
                    .WithExistingDocumentRecord("app", DataSourceType.UsptoTsdr, "ObjId");

                f.DataDownloadLocationResolver.Resolve(null).ReturnsForAnyArgs("MyPath");

                var doc = new Document
                {
                    ApplicationNumber = "app",
                    Source = DataSourceType.UsptoTsdr,
                    DocumentObjectId = "ObjId",
                    DocumentDescription = "b",
                    MediaType = "abc",
                    SourceUrl = "http://somewhere"
                };
                await f.Subject.Download(_dataDownload, doc, f.DocumentDownloadClient.Download);

                f.DocumentDownloadClient.Received(1).Download("app", "ObjId", "b", "abc", "http://somewhere","MyPath");
            }

            [Fact]
            public async Task FeedsInformationToScheduleInsights()
            {
                var f = new DownloadDocumentFixture(Db);

                f.DataDownloadLocationResolver.Resolve(null).ReturnsForAnyArgs("MyPath");

                var doc = new Document
                {
                    ApplicationNumber = "app",
                    RegistrationNumber = "reg",
                    Source = DataSourceType.UsptoTsdr,
                    DocumentObjectId = "ObjId",
                    DocumentDescription = Fixture.String(),
                    DocumentCategory = Fixture.String(),
                    PageCount = Fixture.Integer(),
                    MailRoomDate = Fixture.PastDate()
                };

                await f.Subject.Download(_dataDownload, doc, f.DocumentDownloadClient.Download);

                var document = Db.Set<Document>().First();

                f.ScheduleRuntimeEvents.DocumentProcessed(_dataDownload.Id, document);
            }

            [Fact]
            public async Task SavesDocumentDatabaseRecord()
            {
                var f = new DownloadDocumentFixture(Db);

                f.DataDownloadLocationResolver.Resolve(null).ReturnsForAnyArgs("MyPath");

                var doc = new Document
                {
                    ApplicationNumber = "app",
                    RegistrationNumber = "reg",
                    PublicationNumber = "pub",
                    Source = DataSourceType.UsptoTsdr,
                    DocumentObjectId = "ObjId",
                    DocumentDescription = Fixture.String(),
                    DocumentCategory = Fixture.String(),
                    PageCount = Fixture.Integer(),
                    MailRoomDate = Fixture.PastDate()
                };

                f.DownloadStatusCalculator
                 .GetDownloadStatus(DataSourceType.UsptoTsdr)
                 .Returns(DocumentDownloadStatus.Downloaded);

                await f.Subject.Download(_dataDownload, doc, f.DocumentDownloadClient.Download);

                var document = Db.Set<Document>().First();

                Assert.Equal("app", document.ApplicationNumber);
                Assert.Equal("reg", document.RegistrationNumber);
                Assert.Equal("pub", document.PublicationNumber);
                Assert.Equal("ObjId", document.DocumentObjectId);
                Assert.Equal(doc.DocumentDescription, document.DocumentDescription);
                Assert.Equal(doc.DocumentCategory, document.DocumentCategory);
                Assert.Equal(doc.PageCount, document.PageCount);
                Assert.Equal(doc.MailRoomDate, document.MailRoomDate);
                Assert.Equal(DataSourceType.UsptoTsdr, document.Source);
                Assert.Equal(DocumentDownloadStatus.Downloaded, document.Status);
                Assert.NotNull(document.FileStore);
                Assert.Equal("ObjId.pdf", document.FileStore.OriginalFileName);
                Assert.Equal("MyPath", document.FileStore.Path);
                Assert.Equal(Fixture.Today(), document.CreatedOn);
                Assert.Equal(Fixture.Today(), document.UpdatedOn);
            }
        }

        public class DownloadDocumentFixture : IFixture<PtoDocument>
        {
            readonly InMemoryDbContext _db;

            public DownloadDocumentFixture(InMemoryDbContext db)
            {
                _db = db;
                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();
                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();
                DocumentDownloadClient = Substitute.For<IDocumentDownloadClient>();
                DownloadStatusCalculator = Substitute.For<ICalculateDownloadStatus>();

                Subject = new PtoDocument(db, DataDownloadLocationResolver, ScheduleRuntimeEvents,
                                          Fixture.Today, DownloadStatusCalculator);
            }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }

            public IDocumentDownloadClient DocumentDownloadClient { get; set; }

            public ICalculateDownloadStatus DownloadStatusCalculator { get; set; }

            public PtoDocument Subject { get; }

            public DownloadDocumentFixture WithExistingDocumentRecord(string applicationNo, DataSourceType sourceType,
                                                                      string documentObjId)
            {
                new Document
                {
                    ApplicationNumber = "app",
                    RegistrationNumber = "reg",
                    Source = DataSourceType.UsptoTsdr,
                    DocumentObjectId = "ObjId",
                    Errors =
                        @"[{""type"":""Error"",""activityType"":""Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities.DownloadDocument""}]",
                    Status = DocumentDownloadStatus.Failed
                }.In(_db);

                return this;
            }

            public interface IDocumentDownloadClient
            {
                Task Download(string serialNumber, string objectId, string documentName, string mediaType, string sourceUrl, string filePath);
            }
        }
    }
}