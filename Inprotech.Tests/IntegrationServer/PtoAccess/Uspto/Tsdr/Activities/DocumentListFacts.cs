using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

#pragma warning disable 4014

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class DocumentListFacts
    {
        public class ForMethod : FactBase
        {
            readonly DataDownload _dataDownload = new DataDownload
            {
                Case = new EligibleCase {ApplicationNumber = "app", RegistrationNumber = "reg", CaseKey = 999},
                DataSourceType = DataSourceType.UsptoTsdr
            };

            readonly DataDownload _registrationNumberOnlyDataDownload = new DataDownload
            {
                Case = new EligibleCase {RegistrationNumber = "reg", CaseKey = 999},
                DataSourceType = DataSourceType.UsptoTsdr
            };

            [Theory]
            [InlineData(DocumentDownloadStatus.Failed)]
            [InlineData(DocumentDownloadStatus.Pending)]
            public async Task DocumentsWithStillToDownloadStatusAreDownloaded(DocumentDownloadStatus status)
            {
                var f = new DocumentListFixture(Db);

                new Document
                {
                    Source = DataSourceType.UsptoTsdr,
                    DocumentObjectId = "COA20150211095149",
                    ApplicationNumber = "app",
                    Status = status
                }.In(Db);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                var downloadGroup = (ActivityGroup) r.Items.First();
                var downloadActivity = (SingleActivity) downloadGroup.Items.First();

                Assert.Equal("DownloadDocument.Download", downloadActivity.TypeAndMethod());
            }

            [Theory]
            [InlineData(@"audio/mp3")]
            [InlineData(@"audio/wav")]
            public async Task RegisterSoundFilesInDocumentForSpecialProcessing(string mediaType)
            {
                var f = new DocumentListFixture(Db).With(mediaType);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                var downloadGroup = (ActivityGroup) r.Items.First();
                var downloadActivity = (SingleActivity) downloadGroup.Items.First();
                var document = (Document) downloadActivity.Arguments[1];

                Assert.Equal(mediaType, document.MediaType);
            }

            [Theory]
            [InlineData(@"application/xml")]
            [InlineData(@"application/pdf")]
            [InlineData(@"image/tiff")]
            [InlineData(@"image/jpeg")]
            public async Task IgnoreAllOtherMediaTypes(string mediaType)
            {
                var f = new DocumentListFixture(Db).With(mediaType);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                var downloadGroup = (ActivityGroup) r.Items.First();
                var downloadActivity = (SingleActivity) downloadGroup.Items.First();
                var document = (Document) downloadActivity.Arguments[1];

                Assert.Null(document.MediaType);
            }

            [Theory]
            [InlineData(DocumentDownloadStatus.Downloaded)]
            [InlineData(DocumentDownloadStatus.SendToDms)]
            [InlineData(DocumentDownloadStatus.FailedToSendToDms)]
            [InlineData(DocumentDownloadStatus.ScheduledForSendingToDms)]
            [InlineData(DocumentDownloadStatus.SendingToDms)]
            [InlineData(DocumentDownloadStatus.SentToDms)]
            public async Task DocumentsWithAlreadyDownloadedStatusAreNotDownloaded(DocumentDownloadStatus status)
            {
                var f = new DocumentListFixture(Db);

                new Document
                {
                    Source = DataSourceType.UsptoTsdr,
                    DocumentObjectId = "COA20150211095149",
                    ApplicationNumber = "app",
                    Status = status
                }.In(Db);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                /* assertion same as BuildsWorkflowForNoDocumentDownload */
                var first = (SingleActivity) r.Items.ElementAt(0);
                var followedBy = (SingleActivity) r.Items.ElementAt(1);
                var then = (SingleActivity) r.Items.ElementAt(2);

                Assert.Equal("DetailsAvailable.ConvertToCpaXml", first.TypeAndMethod());
                Assert.Equal("NewCaseDetailsNotification.NotifyIfChanged", followedBy.TypeAndMethod());
                Assert.Equal("RuntimeEvents.CaseProcessed", then.TypeAndMethod());
            }

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
                        Source = DataSourceType.UsptoTsdr,
                        DocumentObjectId = "COA20150211095149",
                        ApplicationNumber = "app",
                        Status = DocumentDownloadStatus.Downloaded
                    }.In(Db);
                }

                await f.Subject.For(_dataDownload);

                f.ScheduleRuntimeEvents.Received(1).IncludeDocumentsForCase(_dataDownload.Id, expected);
            }

            [Fact]
            public async Task BuildsWorkflowForDocumentDownload()
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
            }

            [Fact]
            public async Task BuildsWorkflowForNoDocumentDownload()
            {
                var f = new DocumentListFixture(Db);

                /* the document available is already downloaded - status of Downloaded */
                new Document
                {
                    Source = DataSourceType.UsptoTsdr,
                    DocumentObjectId = "COA20150211095149",
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
            public async Task ConstructsDocumentObjectId()
            {
                var f = new DocumentListFixture(Db);

                var r = (ActivityGroup) await f.Subject.For(_dataDownload);

                var downloadGroup = (ActivityGroup) r.Items.First();
                var downloadActivity = (SingleActivity) downloadGroup.Items.First();
                var documentObjectId = ((Document) downloadActivity.Arguments[1]).DocumentObjectId;

                Assert.Equal("COA20150211095149", documentObjectId);
            }

            [Fact]
            public async Task DownloadsAndSavesDocumentList()
            {
                var f = new DocumentListFixture(Db);
                f.DataDownloadLocationResolver.Resolve(null).ReturnsForAnyArgs("MyPath");
                await f.Subject.For(_dataDownload);

                f.BufferedStringWriter.Received(1).Write("MyPath", Arg.Any<string>());

                f.TsdrClient.Received(1).DownloadDocumentsList("app", "reg");
            }

            [Fact]
            public async Task GetsMissingApplicationNumberFromDocumentsList()
            {
                var f = new DocumentListFixture(Db);

                var r = (ActivityGroup) await f.Subject.For(_registrationNumberOnlyDataDownload);

                var downloadGroup = (ActivityGroup) r.Items.First();
                var downloadActivity = (SingleActivity) downloadGroup.Items.First();
                var document = (Document) downloadActivity.Arguments[1];

                Assert.Equal("86440740", document.ApplicationNumber);
                Assert.Equal("reg", document.RegistrationNumber);
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
            const string DocumentListXml = @"<DocumentList xmlns='urn:aaa'>
<Document>
<SerialNumber>86440740</SerialNumber>
<RegistrationNumber>987654</RegistrationNumber>
<DocumentTypeCode>COA</DocumentTypeCode>
<DocumentTypeCodeDescriptionText>Teas Change of Owner Address</DocumentTypeCodeDescriptionText>
<MailRoomDate>2015-02-10-05:00</MailRoomDate>
<ScanDateTime>2015-02-11T09:51:49.000-05:00</ScanDateTime>
<TotalPageQuantity>1</TotalPageQuantity>
</Document>
</DocumentList>";

            public DocumentListFixture(InMemoryDbContext db)
            {
                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

                BufferedStringWriter = Substitute.For<IBufferedStringWriter>();

                TsdrClient = Substitute.For<ITsdrClient>();
                TsdrClient.DownloadDocumentsList(null, null).ReturnsForAnyArgs(DocumentListXml);

                TsdrSettings = Substitute.For<ITsdrSettings>();
                TsdrSettings.DocsListNs.Returns("urn:aaa");

                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

                Subject = new DocumentList(db, DataDownloadLocationResolver, BufferedStringWriter,
                                           TsdrClient, TsdrSettings, ScheduleRuntimeEvents);
            }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }
            public IBufferedStringWriter BufferedStringWriter { get; set; }
            public ITsdrClient TsdrClient { get; set; }
            public ITsdrSettings TsdrSettings { get; set; }
            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }
            public DocumentList Subject { get; }

            public DocumentListFixture With(string mediaType)
            {
                var mediaTypeXmlFragment = "<PageMediaTypeList><PageMediaTypeName>" + mediaType + "</PageMediaTypeName></PageMediaTypeList>";

                var xml = DocumentListXml.Replace("</Document>", mediaTypeXmlFragment + "</Document>");

                TsdrClient.DownloadDocumentsList(null, null).ReturnsForAnyArgs(xml);

                return this;
            }
        }
    }
}