using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.PtoAccess;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MessageQueueMonitor;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.MessageQueueMonitor
{
    public class DequeueUsptoMessagesJobFacts : FactBase
    {
        class DequeueUsptoMessagesJobFixture : IFixture<DequeueUsptoMessagesJob>
        {
            const string Format = "yyyy-MM-dd";

            public readonly IEnumerable<Message> ReturnMessages = new List<Message>
            {
                new Message
                {
                    Meta = new Meta {ServiceId = Fixture.String(), EventTimeStamp = Fixture.Today().ToString(Format)},
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
                    Meta = new Meta {ServiceId = Fixture.String(), EventTimeStamp = Fixture.Today().ToString(Format)},
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

            public DequeueUsptoMessagesJobFixture(InMemoryDbContext db)
            {
                Db = db;
                PrivatePairService = Substitute.For<IPrivatePairService>();
                PersistJobState = Substitute.For<IPersistJobState>();
                InnographyPrivatePairSettingsValidator = Substitute.For<IInnographyPrivatePairSettingsValidator>();
                var securityContext = Substitute.For<ISecurityContext>();
                FileLocationResolver = Substitute.For<IUsptoMessageFileLocationResolver>();
                securityContext.User.Returns(new User());
                FileSystem = Substitute.For<IFileSystem>();
                Logger = Substitute.For<IBackgroundProcessLogger<IDequeueUsptoMessagesJob>>();

                Subject = new DequeueUsptoMessagesJob(PrivatePairService, PersistJobState, InnographyPrivatePairSettingsValidator, FileSystem, FileLocationResolver, Logger);
            }

            public IUsptoMessageFileLocationResolver FileLocationResolver { get; }
            public IInnographyPrivatePairSettingsValidator InnographyPrivatePairSettingsValidator { get; }
            public IPersistJobState PersistJobState { get; }
            public IPrivatePairService PrivatePairService { get; }
            public IFileSystem FileSystem { get; }

            public IBackgroundProcessLogger<IDequeueUsptoMessagesJob> Logger { get; }

            InMemoryDbContext Db { get; }

            public DequeueUsptoMessagesJob Subject { get; }

            public DequeueUsptoMessagesJobFixture WithScheduleSetting(bool isValid = true, bool alreadyInProgress = false)
            {
                InnographyPrivatePairSettingsValidator.HasValidSchedule().Returns((isValid, alreadyInProgress, new Schedule { Id = 1 }.In(Db)));
                return this;
            }

            public DequeueUsptoMessagesJobFixture WithDefaultData()
            {
                PrivatePairService.DequeueMessages().Returns(ReturnMessages, new List<Message>());
                return this;
            }
        }

        [Fact]
        public async Task DoesNotPerformDbOperationsIfNoMessages()
        {
            var fixture = new DequeueUsptoMessagesJobFixture(Db)
                .WithScheduleSetting();

            fixture.PrivatePairService.DequeueMessages().Returns(new List<Message>());

            await fixture.Subject.Execute(1);

            fixture.PersistJobState.DidNotReceiveWithAnyArgs().Save(Arg.Any<long>(), Arg.Any<DequeueUsptoMessagesJobStatus>()).IgnoreAwaitForNSubstituteAssertion();
            fixture.PrivatePairService.Received(1).DequeueMessages().IgnoreAwaitForNSubstituteAssertion();
            Db.DidNotReceiveWithAnyArgs().Set<MessageStore>();
        }

        [Fact]
        public async Task IfSavingFileThrowsExceptionPersistJobStateIsCalled()
        {
            var fixture = new DequeueUsptoMessagesJobFixture(Db)
                        .WithDefaultData()
                        .WithScheduleSetting();

            fixture.FileSystem.When((f) => f.WriteAllText(Arg.Any<string>(), Arg.Any<string>())).Do((_) => throw new Exception());

            await fixture.Subject.Execute(1);

            fixture.PersistJobState.Received(1).Save(Arg.Any<long>(), Arg.Any<DequeueUsptoMessagesJobStatus>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task DoesNotProcessIfScheduleIsAlreadyInProgress()
        {
            var fixture = new DequeueUsptoMessagesJobFixture(Db)
                .WithScheduleSetting(true, true);

            var second = await fixture.Subject.Execute(2);

            Assert.Equal(typeof(NullActivity), ((SingleActivity)second).Type);
            fixture.PersistJobState.Received(1).Save(2, Arg.Any<DequeueUsptoMessagesJobStatus>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void GetJobShouldReturnCorrectActivity()
        {
            var fixture = new DequeueUsptoMessagesJobFixture(Db);
            var result = fixture.Subject.GetJob(1, null);

            Assert.Equal(typeof(IDequeueUsptoMessagesJob), result.Type);
            Assert.Equal("Execute", result.Name);
        }

        [Fact]
        public async Task StoresMessagesInDb()
        {
            var fixture = new DequeueUsptoMessagesJobFixture(Db)
                          .WithScheduleSetting()
                          .WithDefaultData();
            var messageFolderLocation = Fixture.String();
            fixture.FileLocationResolver.ResolveMessagePath().Returns(messageFolderLocation);

            await fixture.Subject.Execute(1);

            fixture.PersistJobState.DidNotReceiveWithAnyArgs().Save(Arg.Any<long>(), Arg.Any<DequeueUsptoMessagesJobStatus>()).IgnoreAwaitForNSubstituteAssertion();
            fixture.PrivatePairService.Received(2).DequeueMessages().IgnoreAwaitForNSubstituteAssertion();
            fixture.FileSystem.Received(1).WriteAllText(Arg.Is<string>(_ => _.StartsWith(messageFolderLocation)), Arg.Any<string>());
        }

        [Fact]
        public async Task ValidateScheduleSettings()
        {
            var fixture = new DequeueUsptoMessagesJobFixture(Db).WithScheduleSetting(false);
            var result = await fixture.Subject.Execute(1);

            Assert.Equal(typeof(NullActivity), ((SingleActivity)result).Type);
            fixture.PersistJobState.DidNotReceive().Save(Arg.Any<long>(), Arg.Any<DequeueUsptoMessagesJobStatus>()).IgnoreAwaitForNSubstituteAssertion();
        }
    }
}