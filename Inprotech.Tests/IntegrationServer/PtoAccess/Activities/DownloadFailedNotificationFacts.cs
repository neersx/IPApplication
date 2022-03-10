using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Activities
{
    public class DownloadFailedNotificationFacts
    {
        public class NotifyMethod : FactBase
        {
            readonly DataDownload _faultingDownload = new DataDownload
            {
                Case = new EligibleCase
                {
                    CaseKey = 999
                }
            };

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.Epo)]
            public async Task CreatesNewCaseIfCaseIsNotAvailable(DataSourceType source)
            {
                _faultingDownload.DataSourceType = source;

                var f = new DownloadFailedNotificationFixture(Db);
                await f.Subject.Notify(_faultingDownload);

                Assert.NotNull(Db.Set<Case>().SingleOrDefault());
            }

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.Epo)]
            public async Task CreatesNewCaseNotificationIfNotAvailable(DataSourceType source)
            {
                _faultingDownload.DataSourceType = source;

                var f = new DownloadFailedNotificationFixture(Db);
                await f.Subject.Notify(_faultingDownload);

                Assert.NotNull(Db.Set<CaseNotification>().SingleOrDefault());
            }

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.Epo)]
            public async Task DoesNotCreateAnExistingCase(DataSourceType source)
            {
                _faultingDownload.DataSourceType = source;

                new Case
                {
                    Source = source,
                    CorrelationId = _faultingDownload.Case.CaseKey
                }.In(Db);

                var f = new DownloadFailedNotificationFixture(Db);
                await f.Subject.Notify(_faultingDownload);

                Assert.NotNull(Db.Set<Case>().SingleOrDefault());
            }

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr, true)]
            [InlineData(DataSourceType.UsptoTsdr, false)]
            [InlineData(DataSourceType.Epo, true)]
            [InlineData(DataSourceType.Epo, false)]
            public async Task UpdatesTheExistingNotification(DataSourceType source, bool reviewed)
            {
                _faultingDownload.DataSourceType = source;

                var cn = new CaseNotification
                {
                    Body = @"[{""a"":""a""}]",
                    Case = new Case
                    {
                        Source = source,
                        CorrelationId = _faultingDownload.Case.CaseKey
                    },
                    Type = CaseNotificateType.Error,
                    IsReviewed = reviewed
                }.In(Db);

                var f = new DownloadFailedNotificationFixture(Db);

                var j = new[] {JObject.Parse("{\"e\":\"e\"}")};

                f.GlobErrors.For(_faultingDownload)
                 .Returns(Task.FromResult(j.AsEnumerable()));

                await f.Subject.Notify(_faultingDownload);

                Assert.False(Db.Set<CaseNotification>().Contains(cn));

                var notification = Db.Set<CaseNotification>().Single();

                Assert.Equal("[{\"e\":\"e\"}]", notification.Body);
                Assert.False(notification.IsReviewed);
            }

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.Epo)]
            public async Task FeedsInformationToScheduleInsights(DataSourceType source)
            {
                _faultingDownload.DataSourceType = source;

                var c = new Case
                {
                    Source = source,
                    CorrelationId = _faultingDownload.Case.CaseKey
                }.In(Db);

                var artifacts = new byte[0];

                var f = new DownloadFailedNotificationFixture(Db);

                f.ArtefactsService.CreateCompressedArchive("path").Returns(artifacts);

                await f.Subject.Notify(_faultingDownload);

                f.ScheduleRuntimeEvents.Received(1).CaseFailed(_faultingDownload.Id, c, artifacts);
            }
        }

        public class DownloadFailedNotificationFixture : IFixture<DownloadFailedNotification>
        {
            public DownloadFailedNotificationFixture(InMemoryDbContext db)
            {
                GlobErrors = Substitute.For<IGlobErrors>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();
                DataDownloadLocationResolver.ResolveForErrorLog(Arg.Any<DataDownload>()).Returns("path");

                ArtefactsService = Substitute.For<IArtifactsService>();

                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

                Subject = new DownloadFailedNotification(db, Fixture.Today, GlobErrors, DataDownloadLocationResolver, ArtefactsService, ScheduleRuntimeEvents);
            }

            public IGlobErrors GlobErrors { get; set; }

            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public IArtifactsService ArtefactsService { get; set; }

            public DownloadFailedNotification Subject { get; }
        }
    }
}