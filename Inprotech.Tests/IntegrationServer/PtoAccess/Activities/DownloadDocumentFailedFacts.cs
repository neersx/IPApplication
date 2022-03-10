using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Activities
{
    public class DownloadDocumentFailedFacts
    {
        public class NotifyFailureMethod : FactBase
        {
            readonly DataDownload _dataDownload = new DataDownload();

            readonly Document _document = new Document
            {
                DocumentObjectId = "12345"
            };

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.Epo)]
            public async Task CreatesDocumentWithError(DataSourceType sourceType)
            {
                var f = new DownloadDocumentFailedFixture(Db)
                    .WithReturn("{\"e\":\"e\"}");

                _dataDownload.DataSourceType = _document.Source = sourceType;

                await f.Subject.NotifyFailure(_dataDownload, _document);

                var persisted = Db.Set<Document>().Single(_ => _.DocumentObjectId == "12345");

                Assert.Equal("[{\"e\":\"e\"}]", persisted.Errors);
                Assert.Equal(DocumentDownloadStatus.Failed, persisted.Status);
            }

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.Epo)]
            public async Task UpdatesDocumentWithError(DataSourceType sourceType)
            {
                new Document
                {
                    DocumentObjectId = "12345",
                    Source = sourceType,
                    Status = DocumentDownloadStatus.Pending,
                    Errors = null
                }.In(Db);

                var f = new DownloadDocumentFailedFixture(Db)
                    .WithReturn("{\"e\":\"e\"}");

                _dataDownload.DataSourceType = _document.Source = sourceType;

                await f.Subject.NotifyFailure(_dataDownload, _document);

                var persisted = Db.Set<Document>().Single(_ => _.DocumentObjectId == "12345");

                Assert.Equal("[{\"e\":\"e\"}]", persisted.Errors);
                Assert.Equal(DocumentDownloadStatus.Failed, persisted.Status);
            }

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.Epo)]
            public async Task RecordsFailedDownload(DataSourceType sourceType)
            {
                new Document
                {
                    DocumentObjectId = "12345",
                    Source = sourceType,
                    Status = DocumentDownloadStatus.Pending,
                    Errors = null
                }.In(Db);

                var f = new DownloadDocumentFailedFixture(Db)
                    .WithReturn("{\"e\":\"e\"}");

                var artifacts = new byte[0];

                f.ArtefactsService.CreateCompressedArchive("path").Returns(artifacts);

                _dataDownload.DataSourceType = _document.Source = sourceType;

                await f.Subject.NotifyFailure(_dataDownload, _document);

                f.ScheduleRuntimeEvents.Received(1).DocumentFailed(_dataDownload.Id, Arg.Any<Document>(), artifacts);
            }
        }

        public class DownloadDocumentFailedFixture : IFixture<DownloadDocumentFailed>
        {
            public DownloadDocumentFailedFixture(InMemoryDbContext db)
            {
                GlobErrors = Substitute.For<IGlobErrors>();

                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

                ArtefactsService = Substitute.For<IArtifactsService>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();
                DataDownloadLocationResolver.Resolve(Arg.Any<DataDownload>()).Returns("path");

                Subject = new DownloadDocumentFailed(db, GlobErrors, Fixture.Today, DataDownloadLocationResolver, ArtefactsService, ScheduleRuntimeEvents);
            }

            public IGlobErrors GlobErrors { get; set; }

            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }

            public IArtifactsService ArtefactsService { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public DownloadDocumentFailed Subject { get; set; }

            public DownloadDocumentFailedFixture WithReturn(string json)
            {
                var j = new[] {JObject.Parse(json)};

                GlobErrors.For(Arg.Any<DataDownload>(), "12345")
                          .Returns(Task.FromResult(j.AsEnumerable()));

                return this;
            }
        }
    }
}