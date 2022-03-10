using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class DueScheduleFacts : FactBase
    {
        [Fact]
        public async Task CallScheduleForAccountAndService()
        {
            var f = new DueScheduleFixture(Db);

            new Sponsorship
            {
                SponsorName = "SponsorName1",
                SponsoredAccount = "SponsoredEmail1",
                CustomerNumbers = "111222,333222",
                CreatedBy = 45,
                CreatedOn = DateTime.Now,
                IsDeleted = false
            }.In(Db);

            new Sponsorship
            {
                SponsorName = "SponsorName2",
                SponsoredAccount = "SponsoredEmail2",
                CustomerNumbers = "7683,32425",
                CreatedBy = 45,
                CreatedOn = DateTime.Now,
                IsDeleted = false
            }.In(Db);

            var s = new Schedule
            {
                Name = "Hello World",
                ExtendedSettings = "{}"
            }.In(Db);

            var guid = new Guid("d348b03e-ce5d-43f8-be7f-c022c9e00aa2");
            var sessionGuid = new Guid("d348b03e-ce5d-43f8-be7f-c022c9e00bb3");
            f.ScheduleRuntimeEvents.StartSchedule(s, guid).ReturnsForAnyArgs(sessionGuid);
            f.ArtifactsLocationResolver.Resolve(Arg.Is<Session>(_ => _.Id.Equals(sessionGuid))).Returns(sessionGuid.ToString());

            var workflow = (ActivityGroup)await f.Subject.Run(s.Id, guid);

            f.ScheduleRuntimeEvents.Received(1).StartSchedule(s, guid);

            f.ArtifactsLocationResolver
             .Received(1)
             .Resolve(Arg.Is<Session>(_ => _.ScheduleId == s.Id && _.CustomerNumber == "111222, 333222, 7683, 32425"));

            f.FileSystem.Received(1).EnsureFolderExists(sessionGuid.ToString());

            Assert.Equal(3, workflow.Items.Count());
            var activity1 = (ActivityGroup)workflow.Items.ElementAt(0);
            var activity11 = (SingleActivity)activity1.Items.ElementAt(0);
            var activity12 = (SingleActivity)activity1.Items.ElementAt(1);
            Assert.True(((Session)activity11.Arguments[0]).Id.Equals(sessionGuid));
            Assert.Equal("ValidateRequiredSettings", activity11.Name);
            Assert.Equal("ValidateExists", activity12.Name);

            var activity2 = (SingleActivity)workflow.Items.ElementAt(1);
            Assert.Equal(sessionGuid, ((Session)activity2.Arguments[0]).Id);
            Assert.Equal("Retrieve", activity2.Name);

            var activity3 = (SingleActivity)workflow.Items.ElementAt(2);
            Assert.Equal(sessionGuid, ((Session)activity3.Arguments[0]).Id);
            Assert.Equal("EndSession", activity3.Name);
        }

        [Fact]
        public async Task CallRecoverableSchedule()
        {
            var f = new DueScheduleFixture(Db);

            new Sponsorship
            {
                SponsorName = "SponsorName1",
                SponsoredAccount = "SponsoredEmail1",
                CustomerNumbers = "111222,333222",
                CreatedBy = 45,
                CreatedOn = DateTime.Now,
                IsDeleted = false
            }.In(Db);

            new Sponsorship
            {
                SponsorName = "SponsorName2",
                SponsoredAccount = "SponsoredEmail2",
                CustomerNumbers = "7683,32425",
                CreatedBy = 45,
                CreatedOn = DateTime.Now,
                IsDeleted = false
            }.In(Db);

            var s = new Schedule
            {
                Name = "Hello World",
                ExtendedSettings = "{TempStorageId: 10001}",
                Type = ScheduleType.Retry
            }.In(Db);

            var guid = new Guid("d348b03e-ce5d-43f8-be7f-c022c9e00aa2");
            var sessionGuid = new Guid("d348b03e-ce5d-43f8-be7f-c022c9e00bb3");
            f.ScheduleRuntimeEvents.StartSchedule(s, guid).ReturnsForAnyArgs(sessionGuid);
            f.ArtifactsLocationResolver.Resolve(Arg.Is<Session>(_ => _.Id.Equals(sessionGuid))).Returns(sessionGuid.ToString());

            var workflow = (ActivityGroup)await f.Subject.Run(s.Id, guid);

            f.ScheduleRuntimeEvents.Received(1).StartSchedule(s, guid);

            f.ArtifactsLocationResolver
             .Received(1)
             .Resolve(Arg.Is<Session>(_ => _.ScheduleId == s.Id && _.CustomerNumber == "111222, 333222, 7683, 32425"));

            f.FileSystem.Received(1).EnsureFolderExists(sessionGuid.ToString());

            Assert.Equal(3, workflow.Items.Count());
            var activity1 = (ActivityGroup)workflow.Items.ElementAt(0);
            var activity11 = (SingleActivity)activity1.Items.ElementAt(0);
            var activity12 = (SingleActivity)activity1.Items.ElementAt(1);
            Assert.True(((Session)activity11.Arguments[0]).Id.Equals(sessionGuid));
            Assert.Equal("ValidateRequiredSettings", activity11.Name);
            Assert.Equal("ValidateExists", activity12.Name);

            var activity2 = (SingleActivity)workflow.Items.ElementAt(1);
            Assert.Equal(sessionGuid, ((Session)activity2.Arguments[0]).Id);
            Assert.Equal("RetrieveRecoverable", activity2.Name);

            var activity3 = (SingleActivity)workflow.Items.ElementAt(2);
            Assert.Equal(sessionGuid, ((Session)activity3.Arguments[0]).Id);
            Assert.Equal("EndSession", activity3.Name);

            //var activity4 = (SingleActivity)workflow.Items.ElementAt(3);
            //Assert.Equal(s.Id, activity4.Arguments[0]);
            //Assert.Equal("Complete", activity4.Name);

            var onCancel = (SingleActivity)workflow.OnCancel;
            Assert.Equal("Complete", onCancel.Name);

            var onAnyFailed = (SingleActivity)workflow.OnAnyFailed;
            Assert.Equal("SaveArtifactAndNotify", onAnyFailed.Name);
        }
    }

    public class DueScheduleFixture : IFixture<DueSchedule>
    {
        public DueScheduleFixture(InMemoryDbContext db)
        {
            FileSystem = Substitute.For<IFileSystem>();
            ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
            ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();
            InnographyPrivatePairSettings = Substitute.For<IInnographyPrivatePairSettings>();
            InnographyPrivatePairSettings.Resolve().Returns(new InnographyPrivatePairSetting
            {
                ClientId = "Inprotech",
                ClientSecret = "bbbccddd",
                PrivatePairSettings = new PrivatePairExternalSettings
                {
                    Services = new Dictionary<string, ServiceCredentials>
                    {
                        {"abcdefg", new ServiceCredentials()}
                    }
                }
            });

            Subject = new DueSchedule(db, FileSystem, ArtifactsLocationResolver,
                                      ScheduleRuntimeEvents);
        }

        public IFileSystem FileSystem { get; }
        public IArtifactsLocationResolver ArtifactsLocationResolver { get; }
        public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; }
        public IInnographyPrivatePairSettings InnographyPrivatePairSettings { get; }
        public DueSchedule Subject { get; }
    }
}