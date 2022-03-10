using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Notifications;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class NewCaseDetailsAvailableNotificationFacts
    {
        public const string AppDetailsSource =
            @"<Transaction xmlns=""http://www.cpasoftwaresolutions.com"">
                    <TransactionHeader>
                        <SenderDetails>
                            <SenderRequestType>Extract Cases Response</SenderRequestType>
                            <SenderRequestIdentifier>{0}</SenderRequestIdentifier>
                        </SenderDetails>
                    </TransactionHeader>
	                <TransactionBody>
                   </TransactionBody></Transaction>";

        public class SendMethod : FactBase
        {
            readonly ApplicationDownload _application = new ApplicationDownload
            {
                CustomerNumber = "70859",
                Number = "PCT1234",
                SessionName = "Blah"
            };

            [Fact]
            public async Task ExtractsTitleCorrectly()
            {
                var title = "blah";
                var f = new NewCaseDetailsAvailableNotificationFixture(Db)
                        .WithAppDetails(title)
                        .WithCase(_application.Number, "old hash");

                await f.Subject.Send(_application);

                f.PtoAccessCase.Received(1).CreateOrUpdateNotification(Arg.Any<Case>(), Arg.Is(title));
            }

            [Fact]
            public async Task HashOfAppDetailsIsConstructedAfterTimeStampIsRemoved()
            {
                var f = new NewCaseDetailsAvailableNotificationFixture(Db)
                        .WithAppDetails()
                        .WithCase(_application.Number);

                await f.Subject.Send(_application);

                f.ContentHasher.DidNotReceive().ComputeHash(AppDetailsSource);
                f.ContentHasher.Received(1).ComputeHash(await f.BufferedStringReader.Read(Arg.Any<string>()));
            }

            [Fact]
            public async Task ReturnsIfNotChanged()
            {
                var f = new NewCaseDetailsAvailableNotificationFixture(Db)
                        .WithAppDetails()
                        .WithHashText("hashed")
                        .WithCase(_application.Number, "hashed");

                await f.Subject.Send(_application);

                f.PtoAccessCase.DidNotReceive().Update(Arg.Any<string>(), Arg.Any<Case>(), "hashed");
                f.PtoAccessCase.DidNotReceive().CreateOrUpdateNotification(Arg.Any<Case>(), Arg.Any<string>());
            }

            [Fact]
            public async Task UpdatesAndNotifies()
            {
                var f = new NewCaseDetailsAvailableNotificationFixture(Db)
                        .WithAppDetails()
                        .WithHashText("hashed")
                        .WithCase(_application.Number, "old hash");

                await f.Subject.Send(_application);

                f.PtoAccessCase.Received(1).Update(Arg.Any<string>(), Arg.Any<Case>(), "hashed");
                f.PtoAccessCase.Received(1).CreateOrUpdateNotification(Arg.Any<Case>(), Arg.Any<string>());
            }

            [Fact]
            public async Task UpdatesOverErrorNotification()
            {
                var f = new NewCaseDetailsAvailableNotificationFixture(Db)
                        .WithAppDetails()
                        .WithHashText("hashed")
                        .WithCase(_application.Number, "hashed")
                        .WithErrorNotification();

                await f.Subject.Send(_application);

                f.PtoAccessCase.Received(1).Update(Arg.Any<string>(), Arg.Any<Case>(), "hashed");
                f.PtoAccessCase.Received(1).CreateOrUpdateNotification(Arg.Any<Case>(), Arg.Any<string>());
            }
        }

        public class SendAlwaysMethod : FactBase
        {
            readonly ApplicationDownload _application = new ApplicationDownload
            {
                SessionName = "Blah",
                CustomerNumber = "70859",
                Number = "PCT1234"
            };

            [Fact]
            public async Task WillAlwaysSendNotification()
            {
                var f = new NewCaseDetailsAvailableNotificationFixture(Db)
                        .WithAppDetails()
                        .WithHashText("hashed")
                        .WithCase(_application.Number, "hashed");

                await f.Subject.SendAlways(_application);

                f.PtoAccessCase.Received(1).Update(Arg.Any<string>(), Arg.Any<Case>(), "hashed");
                f.PtoAccessCase.Received(1).CreateOrUpdateNotification(Arg.Any<Case>(), Arg.Any<string>());
            }
        }

        public class NewCaseDetailsAvailableNotificationFixture : IFixture<NewCaseDetailsAvailableNotification>
        {
            readonly InMemoryDbContext _db;

            public NewCaseDetailsAvailableNotificationFixture(InMemoryDbContext db)
            {
                _db = db;

                PtoAccessCase = Substitute.For<IPtoAccessCase>();

                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                ArtifactsLocationResolver.Resolve(Arg.Any<ApplicationDownload>())
                                         .Returns("application path");

                BufferedStringReader = Substitute.For<IBufferedStringReader>();

                ContentHasher = Substitute.For<IContentHasher>();
                ContentHasher.ComputeHash(Arg.Any<string>()).Returns(c => (string)c[0]);

                Subject = new NewCaseDetailsAvailableNotification(db, PtoAccessCase,
                                                                  ContentHasher,
                                                                  ArtifactsLocationResolver, BufferedStringReader);
            }

            public IPtoAccessCase PtoAccessCase { get; set; }

            public IContentHasher ContentHasher { get; set; }

            public IArtifactsLocationResolver ArtifactsLocationResolver { get; set; }

            public IBufferedStringReader BufferedStringReader { get; set; }

            public NewCaseDetailsAvailableNotification Subject { get; }

            public NewCaseDetailsAvailableNotificationFixture WithAppDetails(string title = "blah")
            {
                BufferedStringReader.Read(null)
                                    .ReturnsForAnyArgs(Task.FromResult(string.Format(AppDetailsSource, title)));

                return this;
            }

            public NewCaseDetailsAvailableNotificationFixture WithCase(string applicationNumber, string version = null)
            {
                new Case
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = applicationNumber,
                    Version = version
                }.In(_db);

                return this;
            }

            public NewCaseDetailsAvailableNotificationFixture WithHashText(string hashed)
            {
                ContentHasher.ComputeHash(Arg.Any<string>()).Returns(hashed);
                return this;
            }

            public NewCaseDetailsAvailableNotificationFixture WithErrorNotification()
            {
                var @case = _db.Set<Case>().Single();

                new CaseNotification
                {
                    Case = @case,
                    CaseId = @case.Id,
                    Type = CaseNotificateType.Error
                }.In(_db);

                return this;
            }
        }
    }
}