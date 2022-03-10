using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration
{
    public class GraphAccessTokenManagerFacts : FactBase
    {
        [Fact]
        public async Task ShouldReturnTokensGetStoredTokenAsyncMethod()
        {
            var f = new GraphAccessTokenManagerFixture(Db);

            const string tokens = "{\"AccessToken\": \"AT\",  \"RefreshToken\": \"RT\",\"OAuth2\": true}";
            var user = new User(Fixture.UniqueName(), false).In(Db);
            new ExternalCredentials {User = user, Password = Fixture.String(), ProviderName = KnownExternalSettings.ExchangeSetting}.In(Db);
            f.CryptoService.Decrypt(Arg.Any<string>()).Returns(tokens);
            var result = await f.Subject.GetStoredTokenAsync(user.Id);
            Assert.NotNull(result);
            Assert.Equal("RT", result.RefreshToken);
            Assert.Equal("AT", result.AccessToken);
            Assert.True(result.OAuth2);
        }

        [Fact]
        public async Task ShouldReturnNullGetStoredTokenAsyncMethod()
        {
            var f = new GraphAccessTokenManagerFixture(Db);

            var user = new User(Fixture.UniqueName(), false).In(Db);
            var result = await f.Subject.GetStoredTokenAsync(user.Id);
            Assert.Null(result);
        }

        [Fact]
        public async Task ShouldReturnFalseRefreshAccessToken()
        {
            var f = new GraphAccessTokenManagerFixture(Db);
            var user = new User(Fixture.UniqueName(), false).In(Db);
            var result = await f.Subject.RefreshAccessToken(user.Id, new ExchangeConfigurationSettings());
            Assert.False(result);
        }

        [Fact]
        public async Task VerifyPreparedScopeFromSettings()
        {
            var f = new GraphAccessTokenManagerFixture(Db);
            var settings = new ExchangeConfigurationSettings
            {
                RefreshTokenNotRequired = false,
                IsReminderEnabled = true
            };
            var result = await f.Subject.PreparedScopeFromSettings(settings);
            Assert.True(result.Contains("Calendars.ReadWrite "));
            Assert.True(result.Contains("Tasks.ReadWrite "));
            Assert.False(result.Contains("Mail.ReadWrite "));
        }

        public class GraphAccessTokenManagerFixture : IFixture<GraphAccessTokenManager>
        {
            public GraphAccessTokenManagerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                Logger = Substitute.For<IBackgroundProcessLogger<IGraphAccessTokenManager>>();
                CryptoService = Substitute.For<IIdentityBoundCryptoService>();
                AppSettings = Substitute.For<IAppSettings>();
                Subject = new GraphAccessTokenManager(DbContext, CryptoService, Logger, AppSettings);
            }

            public IDbContext DbContext { get; set; }
            public IIdentityBoundCryptoService CryptoService { get; set; }
            public IAppSettings AppSettings { get; set; }
            public IBackgroundProcessLogger<IGraphAccessTokenManager> Logger { get; set; }
            public GraphAccessTokenManager Subject { get; set; }
        }
    }
}