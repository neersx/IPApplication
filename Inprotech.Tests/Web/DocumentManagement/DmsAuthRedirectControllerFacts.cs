using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.DmsIntegration.Component.iManage.v10;
using Inprotech.Web.DocumentManagement;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Messages;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.DocumentManagement
{
    public class DmsAuthRedirectControllerFacts
    {
        public class Authenticate : FactBase
        {
            [Fact]
            public async Task CallAuthenticate()
            {
                var f = new DmsAuthRedirectControllerFixture();
                f.Subject.Request = new HttpRequestMessage(HttpMethod.Get, new Uri("http://localhost/cpaimproma/api/dms/authorize"));
                var result = await f.Subject.Authorize(Fixture.String());
                Assert.NotNull(result);
                var message = await result.ExecuteAsync(new CancellationToken());
                Assert.Equal(message.StatusCode, HttpStatusCode.Found);
                Assert.Equal(message.RequestMessage.RequestUri.ToString(), "http://localhost/cpaimproma/api/dms/authorize");
                var query = HttpUtility.ParseQueryString(message.Headers.Location.Query);
                var stateId = query.Get("state");
                Assert.Equal("http://localhost/cpaimproma/api/dms/imanage/auth/redirect", query.Get("redirect_uri"));
                var accessToken = new Guid().ToString();
                f.Subject.Request = new HttpRequestMessage(HttpMethod.Get, new Uri($"http://localhost/cpaimproma/api/dms/imanage/auth/redirect?state={stateId}&code={accessToken}"));
                var result2 = await f.Subject.Token();
                Assert.NotNull(result2);
                var message2 = await result2.ExecuteAsync(new CancellationToken());
                Assert.Equal(message2.StatusCode, HttpStatusCode.Found);
                Assert.Equal(message2.Headers.Location.AbsoluteUri, "http://localhost/cpaimproma/signin/redirect/integration");
                f.Bus.Received(1).Publish(Arg.Any<SendMessageToClient>());
            }
        }
    }

    public class DmsAuthRedirectControllerFixture : IFixture<DmsAuthRedirectController>
    {
        public DmsAuthRedirectControllerFixture()
        {
            Bus = Substitute.For<IBus>();
            SecurityContextMock = Substitute.For<ISecurityContext>();
            SecurityContextMock.User.Returns(new User());
            DmsSettingsProvider = Substitute.For<IDmsSettingsProvider>();
            DmsSettingsProvider.OAuth2Setting().ReturnsForAnyArgs(new List<IManageSettings.SiteDatabaseSettings>
            {
                new IManageSettings.SiteDatabaseSettings
                {
                    CallbackUrl = "http://localhost/cpaimproma/api/dms/imanage/auth/redirect\r\nhttp://localhost/cpaimproma/signin/redirect/integration222",
                    AuthUrl = "http://localhost/cpaimproma"
                }
            });
            AccessTokenManager = Substitute.For<IAccessTokenManager>();
            AccessTokenManager.When(w => w.GetAccessToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<IManageSettings.SiteDatabaseSettings>()))
                              .Do(x => { Console.WriteLine(string.Empty); });
            UrlTester = Substitute.For<IUrlTester>();
            Subject = new DmsAuthRedirectController(Bus, SecurityContextMock, DmsSettingsProvider, AccessTokenManager, UrlTester);
        }

        public IUrlTester UrlTester { get; set; }
        public IBus Bus { get; set; }
        public ISecurityContext SecurityContextMock { get; set; }
        public IDmsSettingsProvider DmsSettingsProvider { get; set; }
        public IAccessTokenManager AccessTokenManager { get; set; }
        public DmsAuthRedirectController Subject { get; }
    }
}