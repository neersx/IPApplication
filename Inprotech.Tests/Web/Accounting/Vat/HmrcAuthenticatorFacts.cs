using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.VatReturns;
using NSubstitute;
using NSubstitute.ReturnsExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Vat
{
    public class HmrcAuthenticatorFacts : FactBase
    {
        class HmrcAuthenticatorFixture : IFixture<HmrcAuthenticator>
        {
            public HmrcAuthenticatorFixture()
            {
                ApiClient = Substitute.For<IApiClient>();
                HmrcSettingsResolver = Substitute.For<IHmrcSettingsResolver>();
                HmrcTokenResolver = Substitute.For<IHmrcTokenResolver>();
                Subject = new HmrcAuthenticator(ApiClient, HmrcSettingsResolver, HmrcTokenResolver);
            }

            public IApiClient ApiClient { get; }
            public IHmrcSettingsResolver HmrcSettingsResolver { get; }
            public IHmrcTokenResolver HmrcTokenResolver { get; }

            public HmrcAuthenticator Subject { get; }
        }
        [Fact]
        public async Task CallsTheEndpointCorrectly()
            {
                var stateId = Fixture.String();
                var clientId = Fixture.String();
                var redirectUri = Fixture.String("http://localhost:8080");
                var theUrl = KnownUrls.Test + $"/oauth/authorize?response_type=code&scope=read:vat+write:vat&state={stateId}&client_id={clientId}&redirect_uri={Uri.EscapeDataString(redirectUri)}";

                var f = new HmrcAuthenticatorFixture();
                f.HmrcSettingsResolver.Resolve().Returns(new HmrcVatSettings {ClientId = clientId, IsProduction = false, RedirectUri = redirectUri, BaseUrl = KnownUrls.Test });
                f.ApiClient.GetAsync(Arg.Any<string>()).ReturnsNull();
                await f.Subject.GetAuthCode(stateId);
                await f.ApiClient.Received(1).GetAsync(theUrl);
            }

        [Fact]
        public async Task CallsTheEndpointCorrectlyAndReturnsResponse()
            {
                var authCode = Fixture.String();
                var clientId = Fixture.String();
                var clientSecret = Fixture.String();
                var vrn = Fixture.String();
                var redirectUri = Fixture.String("http://localhost:8080");
                var theUrl = KnownUrls.Test + "/oauth/token";

                var response = new OAuthTokenResponse
                               {
                                   AccessToken = Fixture.String(),
                                   RefreshToken = Fixture.String(),
                                   ExpiresIn = Fixture.Short(),
                                   TokenType = Fixture.String()
                               };
                var theRequest = $"grant_type=authorization_code&code={authCode}&client_secret={clientSecret}&client_id={clientId}&redirect_uri={Uri.EscapeDataString(redirectUri)}";
                var f = new HmrcAuthenticatorFixture();
                f.HmrcSettingsResolver.Resolve().Returns(new HmrcVatSettings {ClientId = clientId, ClientSecret = clientSecret, IsProduction = false, RedirectUri = redirectUri, BaseUrl = KnownUrls.Test});
                f.ApiClient.PostAsync<OAuthTokenResponse>(theUrl, theRequest).Returns(response);
                f.ApiClient.Options.Returns(new ApiClientOptions(ApiClientOptions.ContentTypes.Json));

                var result = await f.Subject.GetToken(authCode, vrn);
                await f.ApiClient.Received(1).PostAsync<OAuthTokenResponse>(theUrl, theRequest);
                Assert.Equal(ApiClientOptions.ContentTypes.Form, f.ApiClient.Options.ContentType);
                Assert.False(f.ApiClient.Options.IgnoreServerCertificateValidation);
                Assert.Equal(response.AccessToken, result.AccessToken);
                Assert.Equal(response.RefreshToken, result.RefreshToken);
                Assert.Equal(response.ExpiresIn, result.ExpiresIn);
                Assert.Equal(response.TokenType, result.TokenType);
            }

        [Fact]
        public async Task RefreshesTheToken()
            {
                var refreshToken = Fixture.String("old");
                var clientId = Fixture.String();
                var clientSecret = Fixture.String();
                var vrn = Fixture.String();
                var theUrl = KnownUrls.Production + "/oauth/token";
                var response = new OAuthTokenResponse
                               {
                                   AccessToken = Fixture.String(),
                                   RefreshToken = Fixture.String("new"),
                                   ExpiresIn = Fixture.Short(),
                                   TokenType = Fixture.String()
                               };
                var theRequest = $"grant_type=refresh_token&refresh_token={refreshToken}&client_secret={clientSecret}&client_id={clientId}";
                var f = new HmrcAuthenticatorFixture();
                f.HmrcSettingsResolver.Resolve().Returns(new HmrcVatSettings {ClientId = clientId, ClientSecret = clientSecret, IsProduction = true, BaseUrl = KnownUrls.Production});
                f.ApiClient.PostAsync<OAuthTokenResponse>(theUrl, theRequest).Returns(response);
                f.ApiClient.Options.Returns(new ApiClientOptions(ApiClientOptions.ContentTypes.Json));

                var result = await f.Subject.RefreshToken(refreshToken, vrn);
                await f.ApiClient.Received(1).PostAsync<OAuthTokenResponse>(theUrl, theRequest);
                Assert.Equal(ApiClientOptions.ContentTypes.Form, f.ApiClient.Options.ContentType);
                Assert.False(f.ApiClient.Options.IgnoreServerCertificateValidation);
                Assert.Equal(response.AccessToken, result.AccessToken);
                Assert.Equal(response.RefreshToken, result.RefreshToken);
                Assert.Equal(response.ExpiresIn, result.ExpiresIn);
                Assert.Equal(response.TokenType, result.TokenType);
                Assert.NotEqual(refreshToken, result.RefreshToken);
            }
    }
}
