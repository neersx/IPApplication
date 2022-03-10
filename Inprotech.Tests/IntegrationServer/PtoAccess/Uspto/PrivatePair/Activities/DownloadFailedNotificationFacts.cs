using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class DownloadFailedNotificationFacts
    {
        public class NotifyMethod : FactBase
        {
            readonly ApplicationDownload _faultingApplicationDownload = new ApplicationDownload
            {
                CustomerNumber = "70859",
                Number = "PCT1234"
            };

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task UpdatesTheExistingNotification(bool reviewed)
            {
                var cn = new CaseNotification
                {
                    Body = @"[{""a"":""a""}]",
                    Case = new Case
                    {
                        Source = DataSourceType.UsptoPrivatePair,
                        ApplicationNumber = _faultingApplicationDownload.Number
                    },
                    Type = CaseNotificateType.Error,
                    IsReviewed = reviewed
                }.In(Db);

                var f = new DownloadFailedNotificationFixture(Db);

                var j = new[] { JObject.Parse("{\"e\":\"e\"}") };

                f.ExceptionGlobber.GlobFor(_faultingApplicationDownload)
                 .Returns(Task.FromResult(j.AsEnumerable()));

                await f.Subject.SaveArtifactAndNotify(_faultingApplicationDownload);

                Assert.False(Db.Set<CaseNotification>().Contains(cn));

                var notification = Db.Set<CaseNotification>().Single();

                Assert.Equal("[{\"e\":\"e\"}]", notification.Body);
                Assert.False(notification.IsReviewed);
            }

            [Fact]
            public async Task CreatesNewCaseIfCaseIsNotAvailable()
            {
                var f = new DownloadFailedNotificationFixture(Db);
                await f.Subject.SaveArtifactAndNotify(_faultingApplicationDownload);

                Assert.NotNull(Db.Set<Case>().SingleOrDefault());
            }

            [Fact]
            public async Task CreatesNewCaseNotificationIfNotAvailable()
            {
                var f = new DownloadFailedNotificationFixture(Db);
                await f.Subject.SaveArtifactAndNotify(_faultingApplicationDownload);

                Assert.NotNull(Db.Set<CaseNotification>().SingleOrDefault());
            }

            [Fact]
            public async Task DoesNotCreateAnExistingCase()
            {
                new Case
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = _faultingApplicationDownload.Number
                }.In(Db);

                var f = new DownloadFailedNotificationFixture(Db);
                await f.Subject.SaveArtifactAndNotify(_faultingApplicationDownload);

                Assert.NotNull(Db.Set<Case>().SingleOrDefault());
            }

            [Fact]
            public async Task IndicateCaseFailed()
            {
                var f = new DownloadFailedNotificationFixture(Db);

                var j = new[] { JObject.Parse("{\"e\":\"e\"}") };

                var artefacts = new byte[0];

                f.ExceptionGlobber.GlobFor(_faultingApplicationDownload)
                 .Returns(Task.FromResult(j.AsEnumerable()));

                f.ArtefactsService.CreateCompressedArchive("path").Returns(artefacts);

                await f.Subject.SaveArtifactAndNotify(_faultingApplicationDownload);

                f.ScheduleRuntimeEvents.Received(1).CaseFailed(_faultingApplicationDownload.SessionId, Arg.Any<Case>(), artefacts);
            }
        }

        public class DownloadFailedNotificationFixture : IFixture<ApplicationDownloadFailed>
        {
            public DownloadFailedNotificationFixture(InMemoryDbContext db)
            {
                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                ArtifactsLocationResolver.Resolve(Arg.Any<ApplicationDownload>()).Returns("path");

                ArtefactsService = Substitute.For<IArtifactsService>();

                ExceptionGlobber = Substitute.For<IGlobErrors>();

                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

                Subject = new ApplicationDownloadFailed(db, Fixture.Today, ExceptionGlobber, ArtifactsLocationResolver, ArtefactsService, ScheduleRuntimeEvents);
            }

            public IGlobErrors ExceptionGlobber { get; set; }

            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }

            public IArtifactsService ArtefactsService { get; set; }

            public IArtifactsLocationResolver ArtifactsLocationResolver { get; set; }

            public ApplicationDownloadFailed Subject { get; }
        }
    }
}