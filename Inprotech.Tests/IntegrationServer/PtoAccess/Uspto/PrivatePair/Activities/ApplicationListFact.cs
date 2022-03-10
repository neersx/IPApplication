using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Extensibility;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class ApplicationListFact
    {
        public class ApplicationListFixture : IFixture<IApplicationList>
        {
            public ApplicationListFixture()
            {
                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                PrivatePairRuntimeEvents = Substitute.For<IPrivatePairRuntimeEvents>();
                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();
                FileSystem = Substitute.For<IFileSystem>();
                RecoveryApplicationNumbersProvider = Substitute.For<IProvideApplicationNumbersToRecover>();
                Subject = new ApplicationList(ArtifactsLocationResolver, FileSystem, PrivatePairRuntimeEvents);
            }

            public IFileSystem FileSystem { get; set; }
            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }
            public IArtifactsLocationResolver ArtifactsLocationResolver { get; set; }
            public IPrivatePairRuntimeEvents PrivatePairRuntimeEvents { get; set; }
            public IProvideApplicationNumbersToRecover RecoveryApplicationNumbersProvider { get; set; }
            public IApplicationList Subject { get; }

            public Session GetSession(string certificateId, string customerNumber, int scheduleId)
            {
                return new Session()
                {
                    CertificateId = certificateId,
                    CustomerNumber = customerNumber,
                    DaysWithinLast = 1,
                    DownloadActivity = DownloadActivityType.All,
                    Id = new Guid("d348b03e-ce5d-43f8-be7f-c022c9e00aa2"),
                    Name = "session",
                    ScheduleId = scheduleId
                };
            }
        }

        [Fact]
        public async Task DispatchDownload()
        {
            var f = new ApplicationListFixture();

            var applications = new List<string>() { "14123456", "14123457" };
            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);

            f.FileSystem.Folders(Path.Combine(session.Id.ToString(), "applications")).ReturnsForAnyArgs(applications);
            f.ArtifactsLocationResolver.Resolve(session).Returns(session.Id.ToString());

            var r = (ActivityGroup)await f.Subject.DispatchDownload(session);
            Assert.Equal(2, r.Items.Count());

            var downloadOne = (SingleActivity)r.Items.First();
            Assert.Equal(applications.First(), ((ApplicationDownload)downloadOne.Arguments[1]).ApplicationId);
            var downloadTwo = (SingleActivity)r.Items.ElementAt(1);
            Assert.Equal(applications.Last(), ((ApplicationDownload)downloadTwo.Arguments[1]).ApplicationId);

            await f.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(session, 2);
        }

        [Fact]
        public async Task DoesNotDispatchDownloadForEmptyApplications()
        {
            var f = new ApplicationListFixture();

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);

            f.FileSystem.Folders(Path.Combine(session.Id.ToString(), "applications")).ReturnsForAnyArgs(new string[0]);
            f.ArtifactsLocationResolver.Resolve(session).Returns(session.Id.ToString());

            var r = (SingleActivity)await f.Subject.DispatchDownload(session);

            Assert.Equal("Inprotech.Integration.Extensions.NullActivity", r.Type.FullName);

            await f.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(session, 0);
        }

        [Theory]
        [InlineData("14565383", "14565383")]
        [InlineData("14565383145653831456538314565383", "14565383145653831456538314565383")]
        [InlineData("14123456", "14123456")]
        [InlineData("PCT14123456", "PCT14123456")]
        [InlineData("PCTUS1563525", "PCT/US15/63525")]
        [InlineData("PCTUS17658620", "PCT/US17/658620")]
        [InlineData("PCTUS991234567", "PCT/US9912/34567")]
        [InlineData("PCTUS9912345678", "PCT/US9912/345678")]
        [InlineData("PCTUS991234567890", "PCTUS991234567890")]
        [InlineData("PCTUS99", "PCTUS99")]
        public async Task BuildsCorrectApplicationNumber(string applicationId, string expected)
        {
            var f = new ApplicationListFixture();
            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);

            f.FileSystem.Folders(Path.Combine(session.Id.ToString(), "applications")).ReturnsForAnyArgs(new[] { applicationId });
            f.ArtifactsLocationResolver.Resolve(session).Returns(session.Id.ToString());

            var r = (ActivityGroup)await f.Subject.DispatchDownload(session);
            Assert.Single(r.Items);

            var downloadOne = (SingleActivity)r.Items.First();
            Assert.Equal(applicationId, ((ApplicationDownload)downloadOne.Arguments[1]).ApplicationId);
            Assert.Equal(expected, ((ApplicationDownload)downloadOne.Arguments[1]).Number);

            await f.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(session, 1);
        }
    }
}

