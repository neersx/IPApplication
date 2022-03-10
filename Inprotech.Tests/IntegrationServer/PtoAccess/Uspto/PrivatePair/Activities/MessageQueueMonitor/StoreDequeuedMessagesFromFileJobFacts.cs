using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.DependencyInjection;
using Inprotech.Integration;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.PtoAccess;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MessageQueueMonitor;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.MessageQueueMonitor
{
    public class StoreDequeuedMessagesFromFileJobFacts : FactBase
    {
        public class DeleteActivity : FactBase
        {
            [Fact]
            public async Task DeletesRecordFromDbIfFileNotFound()
            {
                string fileName = Fixture.String();
                var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db).WithScheduleSetting(false);
                fixture.FileSystem.Exists(fileName).Returns(false);
                new MessageStoreFileQueue() { Path = fileName }.In(Db);

                await fixture.Subject.DeleteFile(fileName);

                Assert.Empty(Db.Set<MessageStoreFileQueue>().ToArray());
            }

            [Fact]
            public async Task DeletesRecordFromDbAfterDeletingFile()
            {
                string fileName = Fixture.String();
                var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db).WithScheduleSetting(false);
                fixture.FileSystem.Exists(fileName).Returns(true);
                fixture.FileSystem.DeleteFile(fileName).Returns(true);

                new MessageStoreFileQueue() { Path = fileName }.In(Db);

                await fixture.Subject.DeleteFile(fileName);

                Assert.Empty(Db.Set<MessageStoreFileQueue>().ToArray());
            }

            [Fact]
            public async Task ThrowsIfCantDeleteFile()
            {
                string fileName = Fixture.String();
                var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db).WithScheduleSetting(false);
                fixture.FileSystem.Exists(fileName).Returns(true);
                fixture.FileSystem.DeleteFile(fileName).Returns(false);

                new MessageStoreFileQueue() { Path = fileName }.In(Db);

                Assert.ThrowsAsync<Exception>(async () => await fixture.Subject.DeleteFile(fileName)).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        [Fact]
        public async Task ValidateScheduleSettings()
        {
            var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db).WithScheduleSetting(false);
            var result = await fixture.Subject.Execute(1);

            Assert.Equal(typeof(NullActivity), ((SingleActivity)result).Type);
            fixture.PersistJobState.DidNotReceive().Save(Arg.Any<long>(), Arg.Any<Object>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task DoesNotProcessIfScheduleIsAlreadyInProgress()
        {
            var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db)
                .WithScheduleSetting(true, true);

            var second = await fixture.Subject.Execute(2);

            Assert.Equal(typeof(NullActivity), ((SingleActivity)second).Type);
            fixture.PersistJobState.Received(1).Save(2, Arg.Any<Object>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task PerformCleanupIfNoMessages()
        {
            var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db)
                .WithScheduleSetting();

            fixture.PrivatePairService.DequeueMessages().Returns(new List<Message>());

            var result = await fixture.Subject.Execute(1);

            Assert.Equal(typeof(ICleanupMessageStoreJob), ((SingleActivity)result).Type);
            fixture.PersistJobState.DidNotReceiveWithAnyArgs().Save(Arg.Any<long>(), Arg.Any<Object>()).IgnoreAwaitForNSubstituteAssertion();
            Db.DidNotReceiveWithAnyArgs().Set<MessageStore>();
        }

        [Fact]
        public async Task StoresMessagesInDbAndReturnsNoOperation()
        {
            var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db)
                          .WithScheduleSetting()
                          .WithDefaultFileData();

            var result = await fixture.Subject.Execute(1);

            Assert.Equal(typeof(SingleActivity), result.GetType());
            fixture.PersistJobState.DidNotReceiveWithAnyArgs().Save(Arg.Any<long>(), Arg.Any<Object>()).IgnoreAwaitForNSubstituteAssertion();

            fixture.LifetimeScope.Received(1).BeginLifetimeScope();
            fixture.ScheduleSettings.Received(1).AddProcessId(Arg.Any<string>(), 1);

            Assert.Equal(fixture.ReturnMessages.Count(), Db.Set<MessageStore>().Count());
            Assert.Equal(2, Db.Set<Schedule>().Count());
        }

        [Fact]
        public async Task StoresMessagesInDbAndReturnsDeleteFileActivityIfFileDeleteFails()
        {
            var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db)
                          .WithScheduleSetting()
                          .WithDefaultFileData();
            fixture.FileSystem.DeleteFile(Arg.Any<string>()).Returns(false);

            var result = await fixture.Subject.Execute(1);

            Assert.Equal(typeof(ActivityGroup), result.GetType());
            fixture.PersistJobState.DidNotReceiveWithAnyArgs().Save(Arg.Any<long>(), Arg.Any<Object>()).IgnoreAwaitForNSubstituteAssertion();

            fixture.LifetimeScope.Received(1).BeginLifetimeScope();
            fixture.ScheduleSettings.Received(1).AddProcessId(Arg.Any<string>(), 1);

            Assert.Equal(fixture.ReturnMessages.Count(), Db.Set<MessageStore>().Count());
            Assert.Equal(2, Db.Set<Schedule>().Count());
        }

        [Fact]
        public async Task AssignsCurrentProcessIdForMissingSchedule()
        {
            var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db)
                          .WithScheduleSetting()
                          .WithDefaultFileData();

            var existing = new MessageStore() { ProcessId = 3 }.In(Db);

            var result = await fixture.Subject.Execute(1);

            Assert.Equal(fixture.ReturnMessages.Count() + 1, Db.Set<MessageStore>().Count());
            Assert.Equal(existing.ProcessId, Db.Set<MessageStore>().Last().ProcessId);
            Assert.Equal(2, Db.Set<Schedule>().Count());
        }

        [Fact]
        public async Task AssignsNewProcessIdForNewSchedule()
        {
            var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db)
                          .WithScheduleSetting()
                          .WithDefaultFileData();

            var existing = new MessageStore() { ProcessId = Fixture.Integer() }.In(Db);
            fixture.WithCompletedSchedule(existing.ProcessId);

            var result = await fixture.Subject.Execute(1);

            Assert.Equal(fixture.ReturnMessages.Count() + 1, Db.Set<MessageStore>().Count());
            Assert.Equal(existing.ProcessId + 1, Db.Set<MessageStore>().Last().ProcessId);
            Assert.Equal(3, Db.Set<Schedule>().Count());
        }

        [Fact]
        public async Task ReturnsDeleteFileActivityIfFileAlreadyProcessed()
        {
            var fixture = new StoreDequeuedMessagesFromFileJobFixture(Db)
                          .WithScheduleSetting()
                          .WithDefaultFileData();

            new MessageStoreFileQueue() { Path = "1" }.In(Db);

            var result = await fixture.Subject.Execute(1);

            Assert.Equal(typeof(ActivityGroup), result.GetType());
            fixture.PersistJobState.DidNotReceiveWithAnyArgs().Save(Arg.Any<long>(), Arg.Any<Object>()).IgnoreAwaitForNSubstituteAssertion();

            fixture.LifetimeScope.DidNotReceiveWithAnyArgs().BeginLifetimeScope();
            fixture.ScheduleSettings.DidNotReceiveWithAnyArgs().AddProcessId(Arg.Any<string>(), 1);

            Assert.Equal(0, Db.Set<MessageStore>().Count());
            Assert.Equal(1, Db.Set<Schedule>().Count());
        }

        class StoreDequeuedMessagesFromFileJobFixture : IFixture<StoreDequeuedMessagesFromFileJob>
        {
            const string Format = "yyyy-MM-dd";

            public readonly IEnumerable<Message> ReturnMessages = new List<Message>
            {
                new Message
                {
                    Meta = new Meta() {ServiceId = Fixture.String(), EventTimeStamp = Fixture.Today().ToString(Format)},
                    Links = new List<LinkInfo>
                    {
                        new LinkInfo
                        {
                            LinkType = "pdf",
                            Status = "success",
                            Link = @"https://innography-private-pair-staging.s3.us-gov-west-1.amazonaws.com/inprotech/account/d9f057fb04b971fb8c42ee5bb3cf0977/service/uspto/f5262f7f6e654c749c85d4fb162c5d3c/docs/14/14123456/images/14123456-2014-10-03-00007-CTNF.pdf?AWSAccessKeyId=AKIAKOPCFIXRD64JNEFA&Expires=1540955905&Signature=0NG%2FXMUICikSOO2VCADz7FJKIIU%3D",
                            Decrypter = "JVHkS2Mz",
                            Iv = "JVHkS2Mz"
                        },
                        new LinkInfo
                        {
                            LinkType = "biblio",
                            Status = "success",
                            Link = @"https://innography-private-pair-staging.s3.us-gov-west-1.amazonaws.com/inprotech/account/d9f057fb04b971fb8c42ee5bb3cf0977/service/uspto/f5262f7f6e654c749c85d4fb162c5d3c/docs/14/14123456/biblio_14123456.json?AWSAccessKeyId=AKIAKOPCFIXRD64JNEFA&Expires=1540955905&Signature=kMbyPAX8SxQxdjYO16G%2FSrcbKW4%3D",
                            Decrypter = "au0JYW",
                            Iv = "au0JYW"
                        }
                    }
                },
                new Message
                {
                    Meta = new Meta() {ServiceId = Fixture.String(), EventTimeStamp = Fixture.Today().ToString(Format)},
                    Links = new List<LinkInfo>
                    {
                        new LinkInfo
                        {
                            LinkType = "pdf",
                            Status = "success",
                            Link = "https://innography-private-pair-staging.s3.us-gov-west-1.amazonaws.com/inprotech/account/d9f057fb04b971fb8c42ee5bb3cf0977/service/uspto/f5262f7f6e654c749c85d4fb162c5d3c/docs/14/14123457/images/14123457-2018-11-53-00007-CTNF.pdf?AWSAccessKeyId=AKIAKOPCFIXRD64JNEFA&Expires=1540955905&Signature=0NG%2FXMUICikSOO2VCADz7FJKIIU%3D",
                            Decrypter = "JVHkS2Mz",
                            Iv = "JVHkS2Mz"
                        },
                        new LinkInfo
                        {
                            LinkType = "biblio",
                            Status = "success",
                            Link = @"https://innography-private-pair-staging.s3.us-gov-west-1.amazonaws.com/inprotech/account/d9f057fb04b971fb8c42ee5bb3cf0977/service/uspto/f5262f7f6e654c749c85d4fb162c5d3c/docs/14/1412457/biblio_14123457.json?AWSAccessKeyId=AKIAKOPCFIXRD64JNEFA&Expires=1540955905&Signature=kMbyPAX8SxQxdjYO16G%2FSrcbKW4%3D",
                            Decrypter = "au0JYW",
                            Iv = "au0JYW"
                        }
                    }
                }
            };

            public StoreDequeuedMessagesFromFileJobFixture(InMemoryDbContext db)
            {
                Db = db;
                LifetimeScope = Substitute.For<ILifetimeScope>();

                LifetimeScope.BeginLifetimeScope().Returns(LifetimeScope);
                LifetimeScope.Resolve<IRepository>().Returns(Db);
                PrivatePairService = Substitute.For<IPrivatePairService>();
                PersistJobState = Substitute.For<IPersistJobState>();
                ScheduleSettings = Substitute.For<IReadScheduleSettings>();
                InnographyPrivatePairSettingsValidator = Substitute.For<IInnographyPrivatePairSettingsValidator>();
                var securityContext = Substitute.For<ISecurityContext>();

                securityContext.User.Returns(new User());
                FileSystem = Substitute.For<IFileSystem>();
                Subject = new StoreDequeuedMessagesFromFileJob(LifetimeScope, PersistJobState, InnographyPrivatePairSettingsValidator, Fixture.Today, Db, securityContext,
                                                               ScheduleSettings, FileSystem, Substitute.For<IUsptoMessageFileLocationResolver>());
            }

            public IFileSystem FileSystem { get; }
            public IReadScheduleSettings ScheduleSettings { get; }
            public StoreDequeuedMessagesFromFileJob Subject { get; }
            public IInnographyPrivatePairSettingsValidator InnographyPrivatePairSettingsValidator { get; }
            public IPersistJobState PersistJobState { get; }
            public ILifetimeScope LifetimeScope { get; }
            public IPrivatePairService PrivatePairService { get; }

            InMemoryDbContext Db { get; }

            public Schedule Parent { get; private set; }

            public StoreDequeuedMessagesFromFileJobFixture WithScheduleSetting(bool isValid = true, bool alreadyInProgress = false)
            {
                Parent = new Schedule() { Id = 1, Type = ScheduleType.Continuous, DataSourceType = DataSourceType.UsptoPrivatePair }.In(Db);
                InnographyPrivatePairSettingsValidator.HasValidSchedule().Returns((isValid, alreadyInProgress, Parent));
                return this;
            }

            public StoreDequeuedMessagesFromFileJobFixture WithDefaultFileData()
            {
                FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(new List<string>() { "1" });
                FileSystem.ReadAllText(Arg.Any<string>()).Returns(JsonConvert.SerializeObject(ReturnMessages));
                FileSystem.DeleteFile(Arg.Any<string>()).Returns(true);
                return this;
            }

            public StoreDequeuedMessagesFromFileJobFixture WithCompletedSchedule(long currentProcessId)
            {
                var existingSchedule = new Schedule() { ParentId = Parent.Id }.In(Db);
                ScheduleSettings.GetProcessId(existingSchedule).Returns(currentProcessId);
                return this;
            }
        }
    }
}