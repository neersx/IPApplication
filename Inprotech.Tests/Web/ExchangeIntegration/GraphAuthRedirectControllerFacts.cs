using System;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.Tests.Fakes;
using Inprotech.Web.DocumentManagement;
using Inprotech.Web.ExchangeIntegration;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Messages;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ExchangeIntegration
{
    public class GraphAuthRedirectControllerFacts : FactBase
    {
        [Fact]
        public async Task VerifyAuthorizeAndTokenMethods()
        {
            var f = new GraphAuthRedirectControllerFixture(Db);
            f.Subject.Request = new HttpRequestMessage(HttpMethod.Get, new Uri("http://localhost/cpaimproma/api/graph/authorize"));
            var settings = new ExchangeConfigurationSettings { ExchangeGraph = new ExchangeGraph() { ClientId = Fixture.UniqueName(), TenantId = Fixture.UniqueName() } };
            f.Settings.Resolve().Returns(settings);
            f.AppSettings.GraphAuthUrl.Returns("http://localhost/cpaimproma");
            var result = await f.Subject.Authorize(Fixture.String(), Fixture.Integer());
            Assert.NotNull(result);
            var message = await result.ExecuteAsync(new CancellationToken());
            Assert.Equal(message.StatusCode, HttpStatusCode.Found);
            Assert.Equal(message.RequestMessage.RequestUri.ToString(), "http://localhost/cpaimproma/api/graph/authorize");

            var query = HttpUtility.ParseQueryString(message.Headers.Location.Query);
            var stateId = query.Get("state");
            Assert.Equal("http://localhost/cpaimproma/api/graph/auth/redirect", query.Get("redirect_uri"));
            Assert.Equal(settings.ExchangeGraph.TenantId, query.Get("tenant"));
            Assert.Equal(settings.ExchangeGraph.ClientId, query.Get("client_id"));

            var accessToken = Guid.NewGuid().ToString();
            f.Subject.Request = new HttpRequestMessage(HttpMethod.Get, new Uri($"http://localhost/cpaimproma/api/graph/auth/redirect?state={stateId}&code={accessToken}"));
            var result2 = await f.Subject.Token();
            Assert.NotNull(result2);
            var message2 = await result2.ExecuteAsync(new CancellationToken());
            Assert.Equal(message2.StatusCode, HttpStatusCode.Found);
            Assert.Equal(message2.Headers.Location.AbsoluteUri, "http://localhost/cpaimproma/signin/redirect/integration");
            f.Bus.Received(1).Publish(Arg.Any<SendMessageToClient>());
        }
    }

    public class GraphAuthRedirectControllerFixture : IFixture<GraphAuthRedirectController>
    {
        public GraphAuthRedirectControllerFixture(InMemoryDbContext db)
        {
            Bus = Substitute.For<IBus>();
            SecurityContext = Substitute.For<ISecurityContext>();
            Settings = Substitute.For<IExchangeIntegrationSettings>();
            GraphAccessTokenManager = Substitute.For<IGraphAccessTokenManager>();
            UrlTester = Substitute.For<IUrlTester>();
            GraphNotification = Substitute.For<IGraphNotification>();
            AppSettings = Substitute.For<IAppSettings>();
            Logger = Substitute.For<ILogger<GraphAuthRedirectController>>();
            GraphTaskIdCache = Substitute.For<IGraphTaskIdCache>();

            RequestQueueItemModel = Substitute.For<IRequestQueueItemModel>();
            RequestQueueItemModel.Get(Arg.Any<ExchangeRequestQueueItem>(), Arg.Any<string>(), Arg.Any<string>()).Returns(new RequestQueueItem());
            CultureResolver = Substitute.For<IPreferredCultureResolver>();
            CryptoService = Substitute.For<ICryptoService>();
            ExchangeIntegrationController = new ExchangeIntegrationController(db, RequestQueueItemModel, CultureResolver);
            SecurityContext.User.Returns(new User());
            Subject = new GraphAuthRedirectController(Bus, SecurityContext, Settings, GraphAccessTokenManager, UrlTester, GraphNotification, ExchangeIntegrationController, AppSettings, Logger, GraphTaskIdCache);
        }

        public IBus Bus { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public IExchangeIntegrationSettings Settings { get; set; }
        public IGraphAccessTokenManager GraphAccessTokenManager { get; set; }
        public IUrlTester UrlTester { get; set; }
        public IGraphNotification GraphNotification { get; set; }
        public ExchangeIntegrationController ExchangeIntegrationController { get; set; }
        public IAppSettings AppSettings { get; set; }
        public ILogger<GraphAuthRedirectController> Logger { get; set; }
        public IRequestQueueItemModel RequestQueueItemModel { get; set; }
        public IPreferredCultureResolver CultureResolver { get; set; }
        public ICryptoService CryptoService { get; set; }
        public IGraphTaskIdCache GraphTaskIdCache { get; set; }
        public GraphAuthRedirectController Subject { get; }
    }
}