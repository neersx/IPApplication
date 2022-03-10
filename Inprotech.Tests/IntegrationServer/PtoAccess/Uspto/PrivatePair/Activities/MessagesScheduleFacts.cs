using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;
using Common = Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class MessagesScheduleFacts : FactBase
    {
        public class MessagesScheduleFixture : IFixture<Common.IMessages>
        {
            public readonly IEnumerable<Message> ReturnMessages = new List<Message>
            {
                new Message
                {
                    Meta = new Meta(){ServiceId = Fixture.String()},
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
                    Meta = new Meta(){ServiceId = Fixture.String()},
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

            public MessagesScheduleFixture(InMemoryDbContext db)
            {
                Db = db;
                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                PrivatePairService = Substitute.For<IPrivatePairService>();
                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();
                FileSystem = Substitute.For<IFileSystem>();
                UsptoScheduleSettingsTempStorage = Substitute.For<IReadScheduleSettings>();

                ManageRecoveryInfo = Substitute.For<IManageRecoveryInfo>();

                ScheduleRecoverableReader = Substitute.For<IScheduleRecoverableReader>();

                RecoveryApplicationNumbersProvider = Substitute.For<IProvideApplicationNumbersToRecover>();
                SponsorshipHealthCheck = Substitute.For<ISponsorshipHealthCheck>();

                UpdateArtifactMessageIndex = Substitute.For<Common.IUpdateArtifactMessageIndex>();

                ArtifactsService = Substitute.For<IArtifactsService>();
                RequeueMessageDates = Substitute.For<IRequeueMessageDates>();

                Subject = new Common.Messages(FileSystem, ArtifactsLocationResolver, ArtifactsService, UsptoScheduleSettingsTempStorage, ManageRecoveryInfo, ScheduleRecoverableReader,
                                              ScheduleRuntimeEvents, SponsorshipHealthCheck, PrivatePairService, UpdateArtifactMessageIndex, RequeueMessageDates, Db);
            }

            public IPrivatePairService PrivatePairService { get; set; }

            public IFileSystem FileSystem { get; set; }

            public IArtifactsService ArtifactsService { get; set; }

            public IReadScheduleSettings UsptoScheduleSettingsTempStorage { get; set; }

            public IManageRecoveryInfo ManageRecoveryInfo { get; set; }

            public IScheduleRecoverableReader ScheduleRecoverableReader { get; set; }

            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }

            public IArtifactsLocationResolver ArtifactsLocationResolver { get; set; }

            public IProvideApplicationNumbersToRecover RecoveryApplicationNumbersProvider { get; set; }

            public ISponsorshipHealthCheck SponsorshipHealthCheck { get; set; }

            public IRequeueMessageDates RequeueMessageDates { get; }

            InMemoryDbContext Db { get; }

            public Common.IUpdateArtifactMessageIndex UpdateArtifactMessageIndex { get; set; }
            public Common.Messages Subject { get; }

            Common.IMessages IFixture<Common.IMessages>.Subject => throw new NotImplementedException();

            public Session GetSession(string certificateId, string customerNumber, int scheduleId)
            {
                return new Session
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

            public ApplicationDownload GetApplicationDownload(Session session, Message message, string customerNumber)
            {
                return new ApplicationDownload
                {
                    CustomerNumber = session.CustomerNumber,
                    ApplicationId = message.ApplicationId(),
                    SessionId = session.Id,
                    SessionName = session.Name,
                    SessionRoot = session.Root
                };
            }

            public Stream GenerateStreamFromObject(IEnumerable<Message> messages)
            {
                var stream = new MemoryStream();
                var writer = new StreamWriter(stream);
                writer.Write(JsonConvert.SerializeObject(messages));
                writer.Flush();
                stream.Position = 0;
                return stream;
            }

            public MessagesScheduleFixture WithMessageStore(long processId=0)
            {
                foreach (var m in ReturnMessages)
                {
                    if (m?.Meta == null)
                        continue;
                    var link = m.Links?.For(LinkTypes.Pdf);
                    new MessageStore()
                    {
                        ServiceType = m.Meta.ServiceType,
                        ServiceId = m.Meta.ServiceId,
                        MessageTransactionId = m.Meta.TransactionId,
                        MessageText = m.Meta.Message,
                        MessageStatus = m.Meta.Status,
                        MessageTimestamp = Fixture.Today(),
                        MessageData = JsonConvert.SerializeObject(m),
                        LinkStatus = link?.Status,
                        LinkFileName = link?.DocumentName(),
                        LinkApplicationId = m.ApplicationId(),
                        ProcessId = processId
                    }.In(Db);
                }
                return this;
            }
        }

        [Theory]
        [InlineData("PCTIB200751010", "PCT/IB2007/51010")]
        [InlineData("PCTIB2007510010", "PCT/IB2007/510010")]
        [InlineData("PCTIB0751010", "PCT/IB07/51010")]
        [InlineData("PCTIB07510120", "PCT/IB07/510120")]
        [InlineData("29838922", "29838922")]
        public void ReformatApplicationNumber(string applicationId, string applicationNumber)
        {
            Assert.Equal(applicationNumber, applicationId.GetApplicationNumber());
        }

        [Theory]
        [InlineData("PCT/IB2007/51010", "PCTIB200751010")]
        [InlineData("29838922", "29838922")]
        public void SanitizeApplicationNumber(string applicationId, string applicationNumber)
        {
            Assert.Equal(applicationNumber, applicationId.SanitizeApplicationNumber());
        }

        void ValidateActivityGroup(Session session, ActivityGroup retrieveWorkflow)
        {
            Assert.Equal(2, retrieveWorkflow.Items.Count());
            var activity1 = (SingleActivity)retrieveWorkflow.Items.First();
            Assert.Equal(session, (Session)activity1.Arguments[0]);
            Assert.Equal("DispatchMessageFilesForProcessing", activity1.Name);

            var activity2 = (SingleActivity)retrieveWorkflow.Items.ElementAt(1);
            Assert.Equal(session, (Session)activity2.Arguments[0]);
            Assert.Equal("DispatchDownload", activity2.Name);
        }

        [Fact]
        public async Task DispatchIntoApplicationBuckets()
        {
            var f = new MessagesScheduleFixture(Db);

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
            var applicationDownload1 = f.GetApplicationDownload(session, f.ReturnMessages.First(), "f5262f7f6e654c749c85d4fb162c5d3c");
            var applicationDownload2 = f.GetApplicationDownload(session, f.ReturnMessages.ElementAt(1), "f5262f7f6e654c749c85d4fb162c5d3c");

            f.FileSystem.Files(string.Empty).ReturnsForAnyArgs(new List<string> { "messages\\0.json" });
            f.FileSystem.Exists("messages\\0.json").Returns(true);

            f.ArtifactsLocationResolver.Resolve(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applicationDownload1.ApplicationId), "14123456-2014-10-03-00007-CTNF.pdf.json")
             .Returns(Path.Combine(new[] { "applications", "14123456", "14123456-2014-10-03-00007-CTNF.pdf" }));

            f.ArtifactsLocationResolver.Resolve(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applicationDownload2.ApplicationId), "14123457-2018-11-53-00007-CTNF.pdf.json")
             .Returns(Path.Combine(new[] { "applications", "14123457", "14123457-2018-11-53-00007-CTNF.pdf" }));

            f.PrivatePairService.IsServiceRegistered(Arg.Any<string>()).ReturnsForAnyArgs(true);

            using (var stream = f.GenerateStreamFromObject(f.ReturnMessages))
            {
                f.FileSystem.OpenRead("messages\\0.json").Returns(stream);
                await f.Subject.SortIntoApplicationBucket(session, 0);

                f.FileSystem.Received(1).Exists("messages\\0.json");

                f.SponsorshipHealthCheck.Received(f.ReturnMessages.Count()).CheckErrors(Arg.Any<Message>());
                f.SponsorshipHealthCheck.Received(1).SetSponsorshipStatus().IgnoreAwaitForNSubstituteAssertion();

                f.ArtifactsLocationResolver.Received(1).Resolve(session);
                f.ArtifactsLocationResolver.Received(1).Resolve(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applicationDownload1.ApplicationId), "14123456-2014-10-03-00007-CTNF.pdf.json");
                f.ArtifactsLocationResolver.Received(1).Resolve(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applicationDownload2.ApplicationId), "14123457-2018-11-53-00007-CTNF.pdf.json");

                f.FileSystem.Received(1).WriteAllText("applications\\14123456\\14123456-2014-10-03-00007-CTNF.pdf", JsonConvert.SerializeObject(f.ReturnMessages.First()));
                f.FileSystem.Received(1).WriteAllText("applications\\14123457\\14123457-2018-11-53-00007-CTNF.pdf", JsonConvert.SerializeObject(f.ReturnMessages.ElementAt(1)));
            }
        }

        [Fact]
        public async Task DoesNotDispatchUnRegisteredServicesIntoApplicationBuckets()
        {
            var f = new MessagesScheduleFixture(Db);

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
            var applicationDownload1 = f.GetApplicationDownload(session, f.ReturnMessages.First(), "f5262f7f6e654c749c85d4fb162c5d3c");
            var applicationDownload2 = f.GetApplicationDownload(session, f.ReturnMessages.ElementAt(1), "f5262f7f6e654c749c85d4fb162c5d3c");

            f.FileSystem.Files(string.Empty).ReturnsForAnyArgs(new List<string> { "messages\\0.json" });
            f.FileSystem.Exists("messages\\0.json").Returns(true);

            f.ArtifactsLocationResolver.Resolve(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applicationDownload1.ApplicationId), "14123456-2014-10-03-00007-CTNF.pdf.json")
             .Returns(Path.Combine(new[] { "applications", "14123456", "14123456-2014-10-03-00007-CTNF.pdf" }));

            f.ArtifactsLocationResolver.Resolve(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applicationDownload2.ApplicationId), "14123457-2018-11-53-00007-CTNF.pdf.json")
             .Returns(Path.Combine(new[] { "applications", "14123457", "14123457-2018-11-53-00007-CTNF.pdf" }));

            f.PrivatePairService.IsServiceRegistered(f.ReturnMessages.First().Meta.ServiceId).Returns(true);

            using (var stream = f.GenerateStreamFromObject(f.ReturnMessages))
            {
                f.FileSystem.OpenRead("messages\\0.json").Returns(stream);
                await f.Subject.SortIntoApplicationBucket(session, 0);

                f.FileSystem.Received(1).Exists("messages\\0.json");

                f.SponsorshipHealthCheck.Received(1).CheckErrors(Arg.Any<Message>());
                f.SponsorshipHealthCheck.Received(1).SetSponsorshipStatus().IgnoreAwaitForNSubstituteAssertion();

                f.ArtifactsLocationResolver.Received(1).Resolve(session);
                f.ArtifactsLocationResolver.Received(1).Resolve(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applicationDownload1.ApplicationId), "14123456-2014-10-03-00007-CTNF.pdf.json");
                f.ArtifactsLocationResolver.DidNotReceive().Resolve(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applicationDownload2.ApplicationId), "14123457-2018-11-53-00007-CTNF.pdf.json");

                f.FileSystem.Received(1).WriteAllText("applications\\14123456\\14123456-2014-10-03-00007-CTNF.pdf", JsonConvert.SerializeObject(f.ReturnMessages.First()));
                f.FileSystem.DidNotReceive().WriteAllText("applications\\14123457\\14123457-2018-11-53-00007-CTNF.pdf", JsonConvert.SerializeObject(f.ReturnMessages.ElementAt(1)));
            }
        }

        [Fact]
        public async Task DispatchMessages()
        {
            var f = new MessagesScheduleFixture(Db);

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
            f.FileSystem.Files("messages", "*.json").ReturnsForAnyArgs(new List<string> { "messages\\0.json", "messages\\1.json" });

            var sortMessageWorkFlow = (ActivityGroup)await f.Subject.DispatchMessageFilesForProcessing(session);

            f.ArtifactsLocationResolver.Received(1).Resolve(session);
            f.FileSystem.Received(1).Files("messages", "*.json");

            Assert.Equal(2, sortMessageWorkFlow.Items.Count());
            var activity1 = (SingleActivity)sortMessageWorkFlow.Items.First();
            Assert.Equal(0, (int)activity1.Arguments[1]);
            Assert.Equal("SortIntoApplicationBucket", activity1.Name);

            var activity2 = (SingleActivity)sortMessageWorkFlow.Items.ElementAt(1);
            Assert.Equal(1, (int)activity2.Arguments[1]);
            Assert.Equal("SortIntoApplicationBucket", activity2.Name);
            Assert.False(sortMessageWorkFlow.CanContinueAfterHandlingFailure);
        }

        [Fact]
        public async Task RetrieveMessages()
        {
            var f = new MessagesScheduleFixture(Db).WithMessageStore();

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
            f.FileSystem.Files(string.Empty).ReturnsForAnyArgs(new List<string> { "messages\\0.json", "messages\\1.json" });
            
            var retrieveWorkflow = (ActivityGroup)await f.Subject.Retrieve(session);
            
            f.FileSystem.Received(1).WriteAllText("messages\\2.json", JsonConvert.SerializeObject(f.ReturnMessages));
            f.FileSystem.Received(1).WriteAllText(Arg.Any<string>(), Arg.Any<string>());
            f.ArtifactsLocationResolver.Received(1).Resolve(session);

            Assert.Equal(2, retrieveWorkflow.Items.Count());
            var activity1 = (SingleActivity)retrieveWorkflow.Items.First();
            Assert.Equal(session, (Session)activity1.Arguments[0]);
            Assert.Equal("DispatchMessageFilesForProcessing", activity1.Name);

            var activity2 = (SingleActivity)retrieveWorkflow.Items.ElementAt(1);
            Assert.Equal(session, (Session)activity2.Arguments[0]);
            Assert.Equal("DispatchDownload", activity2.Name);
        }

        //[Fact]
        //public async Task RetrieveMessageHttpError()
        //{
        //    var f = new MessagesScheduleFixture(Db);

        //    var exception = new JObject { { "StatusCode", 404 } };

        //    var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
        //    f.FileSystem.Files(string.Empty).ReturnsForAnyArgs(new List<string> { "messages\\0.json", "messages\\1.json" });
        //    f.PrivatePairService.DequeueMessages().Throws(new InnographyIntegrationException(exception, new Exception()));

        //    var retrieveWorkflow = (ActivityGroup)await f.Subject.Retrieve(session);
        //    await f.PrivatePairService.Received(1).DequeueMessages();

        //    Assert.Equal(2, retrieveWorkflow.Items.Count());
        //    var activity1 = (SingleActivity)retrieveWorkflow.Items.First();
        //    Assert.Equal(session, (Session)activity1.Arguments[0]);
        //    Assert.Equal("DispatchMessageFilesForProcessing", activity1.Name);

        //    var activity2 = (SingleActivity)retrieveWorkflow.Items.ElementAt(1);
        //    Assert.Equal(session, (Session)activity2.Arguments[0]);
        //    Assert.Equal("DispatchDownload", activity2.Name);

        //    f.FileSystem.Files(string.Empty).ReturnsForAnyArgs(new List<string>());
        //    await Assert.ThrowsAsync<InnographyIntegrationException>(
        //                                                             async () => await f.Subject.Retrieve(session));
        //}

        //[Fact]
        //public async Task RetrieveMessageParsingError()
        //{
        //    var f = new MessagesScheduleFixture(Db);
        //    var errorMessage = "Parsing Error";

        //    var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
        //    f.PrivatePairService.DequeueMessages().Throws(new PrivatePairServiceException(errorMessage, new Exception()));

        //    f.FileSystem.Files(Arg.Any<string>(), "*.json").ReturnsForAnyArgs(new List<string>(new[] { "1.json", "2.json" }));

        //    var retrieveWorkflow = (ActivityGroup)await f.Subject.Retrieve(session);

        //    f.PrivatePairService.Received(1).DequeueMessages().IgnoreAwaitForNSubstituteAssertion();

        //    f.ScheduleRuntimeEvents.Received(1).MarkUnrecoverable(session.Id, errorMessage);

        //    ValidateActivityGroup(session, retrieveWorkflow);
        //}

        [Fact]
        public async Task RetrieveRecoverableCaseFailures()
        {
            var f = new MessagesScheduleFixture(Db);

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
            f.FileSystem.Files(string.Empty).ReturnsForAnyArgs(new List<string> { "messages\\0.json", "messages\\1.json" });
            f.UsptoScheduleSettingsTempStorage.GetTempStorageId(session.ScheduleId).ReturnsForAnyArgs(1001);
            var recoveryInfo = new RecoveryInfo { ScheduleRecoverableIds = new List<long> { 10001, 10002 } };
            f.ManageRecoveryInfo.GetIds(1001).Returns(new List<RecoveryInfo> { recoveryInfo });
            var artifact = new byte[1];
            f.ScheduleRecoverableReader.GetRecoverable(DataSourceType.UsptoPrivatePair, recoveryInfo.ScheduleRecoverableIds)
             .Returns(new List<FailedItem>
             {
                 new FailedItem {ApplicationNumber = "A1001", ArtifactId = 10001, DataSourceType = DataSourceType.UsptoPrivatePair, ArtifactType = ArtifactType.Case, Artifact = artifact},
                 new FailedItem {ApplicationNumber = "A1002", ArtifactId = 10002, DataSourceType = DataSourceType.UsptoPrivatePair, ArtifactType = ArtifactType.Case, Artifact = artifact}
             });
            f.RequeueMessageDates.GetDateRanges(Arg.Any<Session>()).Returns(new List<(DateTime startDate, DateTime endDate)>(){(Fixture.Today(),Fixture.Today())});

            var retrieveWorkflow = (ActivityGroup)await f.Subject.RetrieveRecoverable(session);
            await f.ArtifactsService.Received(1).ExtractIntoDirectory(artifact, "A1001", Arg.Is<string[]>(s => s[0] == ".log"));
            await f.ArtifactsService.Received(1).ExtractIntoDirectory(artifact, "A1002", Arg.Is<string[]>(s => s[0] == ".log"));

            Assert.Equal(session, (Session)((SingleActivity)retrieveWorkflow.Items.First()).Arguments[0]);
            Assert.Equal("Requeue", ((SingleActivity)retrieveWorkflow.Items.First()).Name);
        }
    }
}