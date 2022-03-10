using System;
using System.Collections.ObjectModel;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class CaseRequiredFacts
    {
        public class DownloadMethod : FactBase
        {
            readonly DataDownload _dataDownload = new DataDownload
            {
                Case = new EligibleCase {ApplicationNumber = "app", RegistrationNumber = "reg", CaseKey = 999},
                DataSourceType = DataSourceType.UsptoTsdr
            };

            [Theory]
            [InlineData("AppNo", null, "ts/cd/casedocs/snAppNo/zip-bundle-download?case=true")]
            [InlineData("Ap/p,No", "RegNo", "ts/cd/casedocs/snAppNo/zip-bundle-download?case=true")]
            [InlineData(null, "RegNo", "ts/cd/casedocs/rnRegNo/zip-bundle-download?case=true")]
            [InlineData(null, "Reg/N,o", "ts/cd/casedocs/rnRegNo/zip-bundle-download?case=true")]
            public async Task DownloadStatusXmlFromTsdrForCase(string applicationNo, string registrationNo,
                                                               string expectedValue)
            {
                var f = new CaseRequiredFixture();
                f.SetupDataDownload(applicationNo, registrationNo);

                await f.Subject.Download(f.DataDownload);

                f.TsdrClient.Received(1)
                 .DownloadStatus(Arg.Is(expectedValue))
                 .IgnoreAwaitForNSubstituteAssertion();

                f.PtoAccessCase.Received(1)
                 .AddCaseFile(f.DataDownload.Case, CaseFileType.MarkImage, Arg.Any<string>(),
                              PtoAccessFileNames.MarkImage, true);
                f.PtoAccessCase.Received(1)
                 .AddCaseFile(f.DataDownload.Case, CaseFileType.MarkThumbnailImage, Arg.Any<string>(),
                              PtoAccessFileNames.MarkThumbnailImage, true);
            }

            [Theory]
            [InlineData("AppNo", null)]
            [InlineData(null, "RegNo")]
            public async Task ExtractsTheAppropriateFilesFromZip(string applicationNo, string registrationNo)
            {
                var f = new CaseRequiredFixture();
                f.SetupDataDownload(applicationNo, registrationNo);

                await f.Subject.Download(f.DataDownload);

                f.ZipStreamHelper.Received(1).ReadEntriesFromStream(Arg.Any<Stream>());
                f.ZipStreamHelper.Received(1)
                 .ExtractIfExists(Arg.Any<ReadOnlyCollection<ZipArchiveEntry>>(), "Blah.png",
                                  Arg.Any<string>(), Arg.Any<string>());
                f.ZipStreamHelper.Received(1)
                 .ExtractIfExists(Arg.Any<ReadOnlyCollection<ZipArchiveEntry>>(), "Blah_status_st96.xml",
                                  Arg.Any<string>(), Arg.Any<string>());
                f.ZipStreamHelper.Received(1)
                 .ExtractIfExists(Arg.Any<ReadOnlyCollection<ZipArchiveEntry>>(), "markThumbnailImage.png",
                                  Arg.Any<string>(), Arg.Any<string>());

                f.ZipStreamHelper.DidNotReceive()
                 .ExtractIfExists(Arg.Any<ReadOnlyCollection<ZipArchiveEntry>>(),
                                  $"{registrationNo}.png", Arg.Any<string>(), Arg.Any<string>());
            }

            [Theory]
            [InlineData("AppNo", null)]
            [InlineData(null, "RegNo")]
            public async Task AddsMarkImageFilesToCase(string applicationNo, string registrationNo)
            {
                var f = new CaseRequiredFixture();
                f.SetupDataDownload(applicationNo, registrationNo);

                await f.Subject.Download(f.DataDownload);

                f.PtoAccessCase.Received(1)
                 .AddCaseFile(f.DataDownload.Case, CaseFileType.MarkImage, Arg.Any<string>(),
                              PtoAccessFileNames.MarkImage, true);
                f.PtoAccessCase.Received(1)
                 .AddCaseFile(f.DataDownload.Case, CaseFileType.MarkThumbnailImage, Arg.Any<string>(),
                              PtoAccessFileNames.MarkThumbnailImage, true);
            }

            [Fact]
            public async Task CaseIsCreated()
            {
                var f = new CaseRequiredFixture();
                await f.Subject.Download(_dataDownload);

                f.PtoAccessCase.Received(1)
                 .EnsureAvailable(_dataDownload.Case)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task OrchestratesAfterDownloadWorkflow()
            {
                var f = new CaseRequiredFixture();
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
                var f = new CaseRequiredFixture();
                _dataDownload.DownloadType = DownloadType.Documents;
                var r = (ActivityGroup) await f.Subject.Download(_dataDownload);

                var first = r.Items.Cast<SingleActivity>().First();
                var second = r.Items.Cast<SingleActivity>().Skip(1).Single();

                Assert.Equal("DocumentList.For", first.TypeAndMethod());
                Assert.Equal("IBuildDmsIntegrationWorkflows.BuildTsdr", second.TypeAndMethod());
            }
        }

        public class CaseRequiredFixture : IFixture<CaseRequired>
        {
            public CaseRequiredFixture()
            {
                ZipStreamHelper = Substitute.For<IZipStreamHelper>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

                PtoAccessCase = Substitute.For<IPtoAccessCase>();

                TsdrClient = Substitute.For<ITsdrClient>();

                var stream = new MemoryStream();
                const string response = "Fake response.";
                stream.Write(Encoding.UTF8.GetBytes(response), 0, response.Length);
                stream.Seek(0, SeekOrigin.Begin);

                TsdrClient.DownloadStatus(Arg.Any<string>())
                          .Returns(Task.FromResult(new Tuple<Stream, string>(stream, "Blah.zip")));

                MockZipExtract();

                Subject = new CaseRequired(ZipStreamHelper, DataDownloadLocationResolver, PtoAccessCase, TsdrClient);
            }

            public IZipStreamHelper ZipStreamHelper { get; set; }

            public IPtoAccessCase PtoAccessCase { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public ITsdrClient TsdrClient { get; set; }

            public DataDownload DataDownload { get; set; }
            public CaseRequired Subject { get; }

            public void SetupDataDownload(string appNo, string regNo)
            {
                DataDownload = new DataDownload
                {
                    Case =
                        new EligibleCase
                        {
                            ApplicationNumber = appNo,
                            RegistrationNumber = regNo
                        },
                    DataSourceType = DataSourceType.UsptoTsdr,
                    Id = Guid.NewGuid(),
                    ScheduleId = 1,
                    Name = "Schedule1"
                };
            }

            void MockZipExtract()
            {
                ZipStreamHelper.ExtractIfExists(Arg.Any<ReadOnlyCollection<ZipArchiveEntry>>(), Arg.Any<string>(),
                                                Arg.Any<string>(), Arg.Any<string>())
                               .ReturnsForAnyArgs(true);
            }
        }
    }
}