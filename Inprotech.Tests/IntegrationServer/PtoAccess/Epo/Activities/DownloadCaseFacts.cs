using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Epo;
using Inprotech.IntegrationServer.PtoAccess.Epo.Activities;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.Activities
{
    public class DownloadCaseFacts
    {
        public class DownloadMethod : FactBase
        {
            readonly DataDownload _dataDownload = new DataDownload
            {
                Case = new EligibleCase {ApplicationNumber = "app", PublicationNumber = "pub", CaseKey = 999},
                DataSourceType = DataSourceType.Epo
            };

            [Fact]
            public async Task DownloadsDataUsingPublicationNumber()
            {
                var thisDownload = new DataDownload
                {
                    Case =
                        new EligibleCase
                        {
                            ApplicationNumber = "1234",
                            PublicationNumber = "4567"
                        },
                    DownloadType = DownloadType.All,
                    DataSourceType = DataSourceType.Epo,
                    Id = Guid.NewGuid(),
                    ScheduleId = 1,
                    Name = "Schedule1"
                };
                var f = new DownloadCaseFixture();
                f.OpsClient.DownloadApplicationData(OpsClient.DownloadByNumberType.Publication, Arg.Any<string>())
                 .Returns(Task.FromResult("SomeXml"));

                await f.Subject.Download(thisDownload);

                f.OpsClient.Received(1)
                 .DownloadApplicationData(OpsClient.DownloadByNumberType.Publication, Arg.Any<string>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.OpsClient.DidNotReceive().DownloadApplicationData(OpsClient.DownloadByNumberType.Application, "1234")
                 .IgnoreAwaitForNSubstituteAssertion();

                f.BufferedStringWriter.Received(1).Write(@"c:\Location", Arg.Any<string>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DownloadsForApplicationNumberWhenNoPublicationNumberData()
            {
                var thisDownload = new DataDownload
                {
                    Case =
                        new EligibleCase
                        {
                            ApplicationNumber = "1234",
                            PublicationNumber = "4567"
                        },
                    DownloadType = DownloadType.All,
                    DataSourceType = DataSourceType.Epo,
                    Id = Guid.NewGuid(),
                    ScheduleId = 1,
                    Name = "Schedule1"
                };
                var f = new DownloadCaseFixture();

                await f.Subject.Download(thisDownload);

                f.OpsClient.Received(1).DownloadApplicationData(OpsClient.DownloadByNumberType.Publication, "4567")
                 .IgnoreAwaitForNSubstituteAssertion();

                f.OpsClient.Received(1).DownloadApplicationData(OpsClient.DownloadByNumberType.Application, "1234")
                 .IgnoreAwaitForNSubstituteAssertion();

                f.BufferedStringWriter.Received(1).Write(@"c:\Location", Arg.Any<string>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task FillsMissingApplicationNumberFromDownloadedData()
            {
                var thisDownload = new DataDownload
                {
                    Case =
                        new EligibleCase
                        {
                            PublicationNumber = "4567"
                        },
                    DownloadType = DownloadType.All,
                    DataSourceType = DataSourceType.Epo,
                    Id = Guid.NewGuid(),
                    ScheduleId = 1,
                    Name = "Schedule1"
                };
                var f = new DownloadCaseFixture();

                f.OpsClient.DownloadApplicationData(OpsClient.DownloadByNumberType.Publication, Arg.Any<string>())
                 .Returns(Task.FromResult("SomeXml"));

                var applicationreference = new applicationreference
                {
                    documentid =
                        new[]
                        {
                            new documentid
                            {
                                country = new country {Text = new[] {"EP"}},
                                docnumber = new docnumber {Text = new[] {"111"}}
                            }
                        }
                };

                var bibData = new bibliographicdata {applicationreference = new[] {applicationreference}};

                f.OpsData.GetBibliographicData(Arg.Any<string>()).Returns(bibData);

                await f.Subject.Download(thisDownload);

                Assert.Equal("111", thisDownload.Case.ApplicationNumber);
            }

            [Fact]
            public async Task OrchestratesAfterDownloadWorkflow()
            {
                var f = new DownloadCaseFixture();
                var r = (ActivityGroup) await f.Subject.Download(_dataDownload);

                var first = (SingleActivity) r.Items.ElementAt(0);
                var followedBy = (SingleActivity) r.Items.ElementAt(1);
                var then = (SingleActivity) r.Items.ElementAt(2);

                Assert.Equal("DetailsAvailable.ConvertToCpaXml", first.TypeAndMethod());
                Assert.Equal("NewCaseDetailsNotification.NotifyIfChanged", followedBy.TypeAndMethod());
                Assert.Equal("RuntimeEvents.CaseProcessed", then.TypeAndMethod());
            }

            [Fact]
            public async Task OrchestratesDownloadDocumentWorkflow()
            {
                var f = new DownloadCaseFixture();
                _dataDownload.DownloadType = DownloadType.Documents;
                var r = (SingleActivity) await f.Subject.Download(_dataDownload);

                Assert.Equal("DocumentList.For", r.TypeAndMethod());
            }
        }

        public class DownloadCaseFixture : IFixture<DownloadCase>
        {
            public DownloadCaseFixture()
            {
                BufferedStringWriter = Substitute.For<IBufferedStringWriter>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

                OpsClient = Substitute.For<IOpsClient>();

                PtoAccessCase = Substitute.For<IPtoAccessCase>();

                OpsData = Substitute.For<IOpsData>();

                DataDownloadLocationResolver.Resolve(Arg.Any<DataDownload>(),
                                                     Arg.Is(PtoAccessFileNames.ApplicationDetails)).ReturnsForAnyArgs(@"c:\Location");

                OpsClient.DownloadApplicationData(
                                                  Inprotech.IntegrationServer.PtoAccess.Epo.OpsClient.DownloadByNumberType.Application,
                                                  Arg.Any<string>())
                         .Returns(Task.FromResult("SomeXml"));

                Subject = new DownloadCase(OpsClient, BufferedStringWriter, DataDownloadLocationResolver,
                                           PtoAccessCase, OpsData);
            }

            public IBufferedStringWriter BufferedStringWriter { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public IOpsClient OpsClient { get; set; }

            public IPtoAccessCase PtoAccessCase { get; set; }

            public IOpsData OpsData { get; set; }
            public DownloadCase Subject { get; }
        }
    }
}