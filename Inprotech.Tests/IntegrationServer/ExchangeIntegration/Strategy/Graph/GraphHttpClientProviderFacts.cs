using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.Security.External;
using Inprotech.Integration;
using Inprotech.Integration.ExchangeIntegration;
using Microsoft.Identity.Client;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.Strategy.Graph
{
    public class GraphHttpClientProviderFacts
    {
        public class GetClientMethod : FactBase
        {
            [Fact]
            public async Task VerifyGetClientMethod()
            {
                var userId = Fixture.Integer();
                var f = new GraphHttpClientProviderFixture();
                f.AppSettings.GraphApiUrl.Returns("https://testgraph.com/");
                var tokens = new CredentialTokens { RefreshToken = Fixture.UniqueName(), AccessToken = Fixture.UniqueName() };
                f.GraphAccessTokenManager.GetStoredTokenAsync(userId).Returns(tokens);
                var result = await f.Subject.GetClient(userId);
                Assert.NotNull(result);
            }
        }
    }

    public class GraphHttpClientProviderFixture : IFixture<GraphHttpClient>
    {
        public GraphHttpClientProviderFixture()
        {
            Logger = Substitute.For<IBackgroundProcessLogger<IGraphHttpClient>>();
            ConfidentialClientApplication = Substitute.For<IConfidentialClientApplication>();
            AppSettings = Substitute.For<IAppSettings>();
            GraphAccessTokenManager = Substitute.For<IGraphAccessTokenManager>();
            BackgroundProcessMessageClient = Substitute.For<IBackgroundProcessMessageClient>();
            Subject = new GraphHttpClient(AppSettings, GraphAccessTokenManager);
        }
        public IBackgroundProcessLogger<IGraphHttpClient> Logger { get; set; }
        public IConfidentialClientApplication ConfidentialClientApplication { get; set; }

        public IAppSettings AppSettings { get; set; }
        public IGraphAccessTokenManager GraphAccessTokenManager { get; set; }
        public IBackgroundProcessMessageClient BackgroundProcessMessageClient { get; set; }
        public GraphHttpClient Subject { get; set; }
    }
}