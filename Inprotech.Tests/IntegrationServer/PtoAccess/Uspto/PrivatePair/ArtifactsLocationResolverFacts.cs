using System;
using System.IO;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class ArtifactsLocationResolverFacts
    {
        public class ResolveForSession
        {
            [Theory]
            [InlineData("70859", "Shawn's download", "d348b03e-ce5d-43f8-be7f-c022c9e00aa2", null,
                "UsptoIntegration", @"UsptoIntegration\Shawn's download\d348b03e-ce5d-43f8-be7f-c022c9e00aa2")]
            [InlineData("70859", "Shawn's download", "d348b03e-ce5d-43f8-be7f-c022c9e00aa2", "100.json",
                "UsptoIntegration", @"UsptoIntegration\Shawn's download\d348b03e-ce5d-43f8-be7f-c022c9e00aa2\100.json")]
            public void BuildsSessionFilePath(string customerNumber,
                                              string sessionName, string sessionId, string fileName, string root, string expectedPath)
            {
                var session = new Session
                {
                    Root = root,
                    Name = sessionName,
                    Id = Guid.Parse(sessionId),
                    CustomerNumber = customerNumber
                };

                var fixture = new ArtifactsLocationResolverFixture();

                fixture.SessionRootResolver.Resolve(session.Id).Returns(fixture.GetSessionRoot(root, sessionName, session.Id));

                var r = fixture.Subject.Resolve(session, fileName);

                Assert.Equal(expectedPath, r);
            }
        }

        public class ResolveForApplication
        {
            [Theory]
            [InlineData("PCT123", "70859", "Shawn's download", "d348b03e-ce5d-43f8-be7f-c022c9e00aa2", null,
                "UsptoIntegration", @"UsptoIntegration\Shawn's download\d348b03e-ce5d-43f8-be7f-c022c9e00aa2\applications\PCT123")]
            [InlineData("PCT123", "70859", "Shawn's download", "d348b03e-ce5d-43f8-be7f-c022c9e00aa2", "14123456-2014-10-03-00007-CTNF.pdf",
                "UsptoIntegration", @"UsptoIntegration\Shawn's download\d348b03e-ce5d-43f8-be7f-c022c9e00aa2\applications\PCT123\14123456-2014-10-03-00007-CTNF.pdf")]
            public void BuildsApplicationFilePath(string appNumber, string customerNumber, string sessionName,
                                                  string sessionId, string fileName, string root, string expectedPath)
            {
                var application = new ApplicationDownload
                {
                    SessionRoot = root,
                    SessionName = sessionName,
                    SessionId = Guid.Parse(sessionId),
                    CustomerNumber = customerNumber,
                    ApplicationId = appNumber
                };

                var fixture = new ArtifactsLocationResolverFixture();

                fixture.SessionRootResolver.Resolve(application.SessionId).Returns(fixture.GetSessionRoot(root, sessionName, application.SessionId));

                var r = fixture.Subject.Resolve(application, fileName);

                Assert.Equal(expectedPath, r);
            }
        }
    }

    internal class ArtifactsLocationResolverFixture : IFixture<ArtifactsLocationResolver>
    {
        public IResolveScheduleExecutionRootFolder SessionRootResolver =
            Substitute.For<IResolveScheduleExecutionRootFolder>();

        public ArtifactsLocationResolver Subject => new ArtifactsLocationResolver(SessionRootResolver);

        public string GetSessionRoot(string root, string name, Guid sessionGuid)
        {
            return Path.Combine(root, name, sessionGuid.ToString());
        }
    }
}