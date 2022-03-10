using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class ScheduleInitialisationFailureFacts
    {
        public class ScheduleInitialisationFailureFixture : IFixture<IScheduleInitialisationFailure>
        {
            public ScheduleInitialisationFailureFixture()
            {
                ExceptionGlobber = Substitute.For<IGlobErrors>();

                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

                FileSystem = Substitute.For<IFileSystem>();
                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                ArtifactsService = Substitute.For<IArtifactsService>();

                Subject = new ScheduleInitialisationFailure(FileSystem, ScheduleRuntimeEvents, ArtifactsLocationResolver, ArtifactsService, ExceptionGlobber);
            }

            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }

            public IGlobErrors ExceptionGlobber { get; set; }
            public IScheduleInitialisationFailure Subject { get; }

            public IFileSystem FileSystem { get; }
            public IArtifactsLocationResolver ArtifactsLocationResolver { get; }
            public IArtifactsService ArtifactsService { get; }
        }

        public class LogMethod : FactBase
        {
            [Fact]
            public async Task GlobsExceptionAndNotify()
            {
                var f = new ScheduleInitialisationFailureFixture();

                var j = new[] { JObject.Parse("{\"e\":\"e\"}") };

                f.ExceptionGlobber
                 .GlobFor(Arg.Any<Session>())
                 .Returns(Task.FromResult(j.AsEnumerable()));

                var schedule = new Schedule().In(Db);

                var session = new Session
                {
                    CustomerNumber = "70859",
                    ScheduleId = schedule.Id
                };

                await f.Subject.Notify(session);

                f.ScheduleRuntimeEvents.Received(1).Failed(session.Id, "[{\"e\":\"e\"}]");
            }

            [Fact]
            public async Task GlobsExceptionSaveArtifactandNotify()
            {
                var f = new ScheduleInitialisationFailureFixture();

                var j = new[] { JObject.Parse("{\"e\":\"e\"}") };

                f.ExceptionGlobber
                 .GlobFor(Arg.Any<Session>())
                 .Returns(Task.FromResult(j.AsEnumerable()));

                var schedule = new Schedule().In(Db);

                var session = new Session
                {
                    CustomerNumber = "70859",
                    ScheduleId = schedule.Id
                };
                var messagefolder = Path.Combine("session", "messages");
                f.ArtifactsLocationResolver.Resolve(session).Returns("sesssion");
                f.ArtifactsLocationResolver.Resolve(session, "messages").Returns(messagefolder);
                f.FileSystem.Folders(Arg.Any<string>()).Returns(new[] { messagefolder });
                f.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(new[] { "1.json" });
                var compressStream = new byte[0];
                f.ArtifactsService.CreateCompressedArchive("session\\messages").Returns(compressStream);

                await f.Subject.SaveArtifactAndNotify(session);

                f.ScheduleRuntimeEvents.Received(1).Failed(session.Id, "[{\"e\":\"e\"}]", compressStream);
            }

            [Fact]
            public async Task GlobsExceptionSaveArtifactandNotifyNoArtifact()
            {
                var f = new ScheduleInitialisationFailureFixture();

                var j = new[] { JObject.Parse("{\"e\":\"e\"}") };

                f.ExceptionGlobber
                 .GlobFor(Arg.Any<Session>())
                 .Returns(Task.FromResult(j.AsEnumerable()));

                var schedule = new Schedule().In(Db);

                var session = new Session
                {
                    CustomerNumber = "70859",
                    ScheduleId = schedule.Id
                };
                var messagefolder = Path.Combine("session", "messages");
                f.ArtifactsLocationResolver.Resolve(session).Returns("sesssion");
                f.ArtifactsLocationResolver.Resolve(session, "messages").Returns(messagefolder);
                f.FileSystem.Folders(Arg.Any<string>()).Returns(new[] { messagefolder });
                f.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(new string[0] );
                var compressStream = new byte[0];
                f.ArtifactsService.CreateCompressedArchive("session\\messages").Returns(compressStream);

                await f.Subject.SaveArtifactAndNotify(session);

                f.ScheduleRuntimeEvents.Received(1).Failed(session.Id, "[{\"e\":\"e\"}]");
            }
        }
    }
}