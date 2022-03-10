using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Extensibility;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class ApplicationDocumentFact
    {
        class ApplicationDocumentFixture : IFixture<IApplicationDocuments>
        {
            public readonly IEnumerable<Message> _returnMessages = new List<Message>
            {
                new Message
                {
                    Meta = new Meta
                    {
                        ServiceId = Fixture.String(),
                        EventDate = Fixture.Today().SetFileStoreMessageEventTimeStamp()
                    },
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
                    Meta = new Meta
                    {
                        ServiceId = Fixture.String(),
                        EventDate = Fixture.Today().SetFileStoreMessageEventTimeStamp()
                    },
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

            public ApplicationDocumentFixture()
            {
                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                PrivatePairRuntimeEvents = Substitute.For<IPrivatePairRuntimeEvents>();
                FileSystem = Substitute.For<IFileSystem>();
                BufferedStringReader = Substitute.For<IBufferedStringReader>();
                BiblioStorage = Substitute.For<IBiblioStorage>();

                Subject = new ApplicationDocuments(ArtifactsLocationResolver, FileSystem, PrivatePairRuntimeEvents, BufferedStringReader, BiblioStorage);
            }

            public IFileSystem FileSystem { get; }
            public IArtifactsLocationResolver ArtifactsLocationResolver { get; }
            public IPrivatePairRuntimeEvents PrivatePairRuntimeEvents { get; }
            public IBufferedStringReader BufferedStringReader { get; }
            public IBiblioStorage BiblioStorage { get; }
            public IApplicationDocuments Subject { get; }

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

            public ApplicationDownload GetApplicationDownload(Session session, string applicationId)
            {
                return new ApplicationDownload
                {
                    CustomerNumber = session.CustomerNumber,
                    Number = applicationId,
                    SessionId = session.Id,
                    SessionName = session.Name,
                    SessionRoot = session.Root
                };
            }
        }

        [Fact]
        public async Task DispatchDownload()
        {
            var f = new ApplicationDocumentFixture();

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
            var applicationDownload = f.GetApplicationDownload(session, "14123456");
            var files = new[] { "14123456-2014-10-03-00007-CTNF.json", "14123457-2018-11-53-00007-CTNF.json" };

            f.FileSystem.Files(Path.Combine(session.Id.ToString(), "applications\\14123456")).ReturnsForAnyArgs(files);
            f.ArtifactsLocationResolver.Resolve(session).Returns(session.Id.ToString());

            f.BufferedStringReader.Read(files.First()).Returns(JsonConvert.SerializeObject(f._returnMessages.First()));
            f.BufferedStringReader.Read(files.Last()).Returns(JsonConvert.SerializeObject(f._returnMessages.Last()));

            var r = await f.Subject.Download(session, applicationDownload);
            Assert.True(r.GetType() == typeof(ActivityGroup));
            Assert.Equal(3, (r as ActivityGroup)?.Items.Count());
            Assert.True(((SingleActivity)((ActivityGroup)r).Items.ElementAt(2)).Type == typeof(IProcessApplicationDocuments));

            await f.PrivatePairRuntimeEvents.Received(1).TrackDocumentProgress(applicationDownload, 2, Arg.Any<AvailableDocument[]>());
        }

        [Fact]
        public async Task MarkCaseProcessedIfNothingToDispatch()
        {
            var f = new ApplicationDocumentFixture();

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
            var applicationDownload = f.GetApplicationDownload(session, "14123456");

            f.FileSystem.Files(Path.Combine(session.Id.ToString(), "applications\\14123456")).ReturnsForAnyArgs(new[] { "14123456-2014-10-03-00007-CTNF.json" });
            f.ArtifactsLocationResolver.Resolve(session).Returns(session.Id.ToString());

            var biblioOnlyMessage = new Message
            {
                Meta = new Meta
                {
                    ServiceId = Fixture.String(),
                    EventDate = Fixture.Today().SetFileStoreMessageEventTimeStamp()
                },
                Links = new List<LinkInfo>
                {
                    new LinkInfo
                    {
                        LinkType = "biblio",
                        Status = "success",
                        Link = @"https://innography-private-pair-staging.s3.us-gov-west-1.amazonaws.com/inprotech/account/d9f057fb04b971fb8c42ee5bb3cf0977/service/uspto/f5262f7f6e654c749c85d4fb162c5d3c/docs/14/1412457/biblio_14123457.json?AWSAccessKeyId=AKIAKOPCFIXRD64JNEFA&Expires=1540955905&Signature=kMbyPAX8SxQxdjYO16G%2FSrcbKW4%3D",
                        Decrypter = "au0JYW",
                        Iv = "au0JYW"
                    }
                }
            };

            f.BufferedStringReader.Read(Arg.Any<string>()).Returns(JsonConvert.SerializeObject(biblioOnlyMessage));

            var r = await f.Subject.Download(session, applicationDownload);
            Assert.True(r.GetType() == typeof(SingleActivity));
            Assert.True(((SingleActivity)r).Type == typeof(IPrivatePairRuntimeEvents));
            Assert.True(((SingleActivity)r).Name == "CaseProcessed");
        }

        [Fact]
        public async Task ReturnsDefaultActivityIfNewerBiblioNotFound()
        {
            var f = new ApplicationDocumentFixture();

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
            var applicationDownload = f.GetApplicationDownload(session, "14123456");
            var files = new[] { "14123456-2014-10-03-00007-CTNF.json", "14123457-2018-11-53-00007-CTNF.json" };
            f.FileSystem.Files(Path.Combine(session.Id.ToString(), "applications\\14123456")).ReturnsForAnyArgs(files);
            f.ArtifactsLocationResolver.Resolve(session).Returns(session.Id.ToString());

            f.BufferedStringReader.Read(files.First()).Returns(JsonConvert.SerializeObject(f._returnMessages.First()));
            f.BufferedStringReader.Read(files.Last()).Returns(JsonConvert.SerializeObject(f._returnMessages.Last()));
            f.BiblioStorage.GetFileStoreBiblioInfo(applicationDownload.ApplicationId).Returns((new FileStore(), Fixture.FutureDate()));

            var r = await f.Subject.Download(session, applicationDownload);

            Assert.True(r.GetType() == typeof(ActivityGroup));
            var activity = (ActivityGroup)r;
            Assert.Equal(3, activity.Items.Count());
            Assert.True(((activity.Items.ElementAt(0) as ActivityGroup)?.Items.ElementAt(0) as SingleActivity).TypeAndMethod() == "NullActivity.NoOperation");
        }

        [Fact]
        public async Task ReturnsNewerActivityIfNewerBiblioFoundByTimestamp()
        {
            var f = new ApplicationDocumentFixture();

            var session = f.GetSession("1234CertificateId", "f5262f7f6e654c749c85d4fb162c5d3c", 1234);
            var applicationDownload = f.GetApplicationDownload(session, "14123456");
            var files = new[] { "14123456-2014-10-03-00007-CTNF.json", "14123457-2018-11-53-00007-CTNF.json" };
            f.FileSystem.Files(Path.Combine(session.Id.ToString(), "applications\\14123456")).ReturnsForAnyArgs(files);
            f.ArtifactsLocationResolver.Resolve(session).Returns(session.Id.ToString());

            f.BufferedStringReader.Read(files.First()).Returns(JsonConvert.SerializeObject(f._returnMessages.First()));
            f.BufferedStringReader.Read(files.Last()).Returns(JsonConvert.SerializeObject(f._returnMessages.Last()));
            f.BiblioStorage.GetFileStoreBiblioInfo(applicationDownload.ApplicationId).Returns((new FileStore(), Fixture.PastDate()));

            var r = await f.Subject.Download(session, applicationDownload);

            Assert.True(r.GetType() == typeof(ActivityGroup));
            var activity = (ActivityGroup)r;
            Assert.Equal(3, activity.Items.Count());
            Assert.Equal("IDocumentDownload.DownloadIfRequired", ((activity.Items.ElementAt(0) as ActivityGroup)?.Items.ElementAt(0) as SingleActivity).TypeAndMethod());
        }
    }
}