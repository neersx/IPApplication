using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Epo;
using Inprotech.IntegrationServer.PtoAccess.Epo.Activities;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

#pragma warning disable 4014

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.Activities
{
    public class DocumentListFacts
    {
        public class ForMethod : FactBase
        {
            readonly DataDownload _dataDownload = new DataDownload
            {
                Case = new EligibleCase {ApplicationNumber = "app", PublicationNumber = "pub", CaseKey = 999},
                DataSourceType = DataSourceType.Epo
            };

            [Theory]
            [InlineData(1, "With No Existing Documents")]
            [InlineData(0, "With Existing Document")]
            public async Task FeedsInformationToScheduleInsights(int expected, string explanation)
            {
                var f = new DocumentListFixture(Db);

                if (explanation == "With Existing Document")
                {
                    new Document
                    {
                        Source = DataSourceType.Epo,
                        DocumentObjectId = "EW8VA27C7905FI4",
                        ApplicationNumber = "app",
                        Status = DocumentDownloadStatus.Downloaded
                    }.In(Db);
                }

                await f.Subject.For(_dataDownload);

                f.ScheduleRuntimeEvents.Received(1).IncludeDocumentsForCase(_dataDownload.Id, expected);
            }

            [Fact]
            public async Task ConstructsDocumentObject()
            {
                var f = new DocumentListFixture(Db);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                var downloadGroup = (ActivityGroup) r.Items.First();
                var downloadActivity = (SingleActivity) downloadGroup.Items.First();
                var documentObject = (Document) downloadActivity.Arguments[1];

                Assert.Equal("EW8VA27C7905FI4", documentObject.DocumentObjectId);
                Assert.Equal("app", documentObject.ApplicationNumber);
                Assert.Equal("pub", documentObject.PublicationNumber);
                Assert.Equal(DataSourceType.Epo, documentObject.Source);
            }

            [Fact]
            public async Task DownloadsAndSavesDocumentList()
            {
                var f = new DocumentListFixture(Db);
                f.DataDownloadLocationResolver.Resolve(null).ReturnsForAnyArgs("MyPath");
                await f.Subject.For(_dataDownload);
                f.BufferedStringWriter.Received(1).Write("MyPath", Arg.Any<string>());

                f.EpRegisterClient.Received(1).DownloadDocumentsList("app");
            }

            [Fact]
            public async Task HandlesError()
            {
                var f = new DocumentListFixture(Db);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                // error thrown from the above ochestrated activities are handled here.
                Assert.NotNull(((ActivityGroup) r.Items.Last()).OnAnyFailed);
            }

            [Fact]
            public async Task OrchestratesAfterDownloadDocumentsTasks()
            {
                var f = new DocumentListFixture(Db);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                var afterDownloadGroup = (ActivityGroup) r.Items.Last();

                var first = (SingleActivity) afterDownloadGroup.Items.ElementAt(0);
                var followedBy = (SingleActivity) afterDownloadGroup.Items.ElementAt(1);
                var thenFollowedBy = (SingleActivity) afterDownloadGroup.Items.ElementAt(2);
                var then = (SingleActivity) afterDownloadGroup.Items.ElementAt(3);

                Assert.Equal("DetailsAvailable.ConvertToCpaXml", first.TypeAndMethod());
                Assert.Equal("DocumentEvents.UpdateFromPto", followedBy.TypeAndMethod());
                Assert.Equal("NewCaseDetailsNotification.NotifyAlways", thenFollowedBy.TypeAndMethod());
                Assert.Equal("RuntimeEvents.CaseProcessed", then.TypeAndMethod());

                Assert.NotNull(afterDownloadGroup.OnAnyFailed);
            }

            [Fact]
            public async Task OrchestratesAfterDownloadTasksWhenNoDocs()
            {
                var f = new DocumentListFixture(Db);

                new Document
                {
                    Source = DataSourceType.Epo,
                    DocumentObjectId = "EW8VA27C7905FI4",
                    ApplicationNumber = "app",
                    Status = DocumentDownloadStatus.Downloaded
                }.In(Db);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                var first = (SingleActivity) r.Items.ElementAt(0);
                var followedBy = (SingleActivity) r.Items.ElementAt(1);
                var then = (SingleActivity) r.Items.ElementAt(2);

                Assert.Equal("DetailsAvailable.ConvertToCpaXml", first.TypeAndMethod());
                Assert.Equal("NewCaseDetailsNotification.NotifyIfChanged", followedBy.TypeAndMethod());
                Assert.Equal("RuntimeEvents.CaseProcessed", then.TypeAndMethod());
            }

            [Fact]
            public async Task OrchestratesDownloadDocumentsTasks()
            {
                var f = new DocumentListFixture(Db);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                var downloadGroup = (ActivityGroup) r.Items.First();
                var downloadActivity = (SingleActivity) downloadGroup.Items.First();

                Assert.Equal("DownloadDocument.Download", downloadActivity.TypeAndMethod());
            }
        }

        public class DocumentListFixture : IFixture<DocumentList>
        {
            const string DocumentListXml = @"<table></table>";

            public DocumentListFixture(InMemoryDbContext db)
            {
                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

                BufferedStringWriter = Substitute.For<IBufferedStringWriter>();

                EpRegisterClient = Substitute.For<IEpRegisterClient>();
                EpRegisterClient.DownloadDocumentsList(Arg.Any<string>())
                                .ReturnsForAnyArgs(Task.FromResult(DocumentListXml));

                EpoSettings = Substitute.For<IEpoSettings>();

                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

                AllDocumentsTabExtractor = Substitute.For<IAllDocumentsTabExtractor>();

                var availableDoc = new AvailableDocument
                {
                    DocumentId = "EW8VA27C7905FI4",
                    Number = "EP07075884",
                    NumberOfPages = 1,
                    Date = Fixture.Today(),
                    Procedure = "Appeal",
                    DocumentName =
                        "F3303.17 Change of the composition of the Board (T), in case Chairman is a legal member"
                };
                AllDocumentsTabExtractor.Extract(Arg.Any<string>()).Returns(new[] {availableDoc});

                Subject = new DocumentList(DataDownloadLocationResolver, BufferedStringWriter,
                                           EpRegisterClient, AllDocumentsTabExtractor, db, ScheduleRuntimeEvents);
            }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }
            public IBufferedStringWriter BufferedStringWriter { get; set; }
            public IEpRegisterClient EpRegisterClient { get; set; }
            public IEpoSettings EpoSettings { get; set; }
            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }
            public IAllDocumentsTabExtractor AllDocumentsTabExtractor { get; set; }
            public DocumentList Subject { get; }
        }
    }
}