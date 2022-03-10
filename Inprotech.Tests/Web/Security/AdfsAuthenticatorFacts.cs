using Inprotech.Infrastructure.Web;
using Inprotech.Web.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class AdfsAuthenticatorFacts
    {
        public AdfsAuthenticatorFacts()
        {
            _adfsSettingsResolver = Substitute.For<IAdfsSettingsResolver>();
            _adfsSettingsResolver.Resolve().Returns(_ => new AdfsSettings(BaseAdfsUrl, ClientId, RelyingPartyAddress, Certificate, ReturnUrls));
            _apiClient = Substitute.For<IApiClient>();
            _apiClient.Options.Returns(new ApiClientOptions(ApiClientOptions.ContentTypes.Json));

            _subject = new AdfsAuthenticator(_adfsSettingsResolver, _apiClient);
        }

        readonly IAdfsSettingsResolver _adfsSettingsResolver;
        readonly IApiClient _apiClient;
        readonly IAdfsAuthenticator _subject;
        const string BaseAdfsUrl = "http://adfs.company.com";
        const string ClientId = "ClientId";
        const string RelyingPartyAddress = "InprotechTrust";
        const string Certificate = "Certificate";
        static readonly string ReturnUrls = $"{{\"url1\":\"http://localhost/cpainpro/apps/api/signin/adfsreturn\" }}";

        [Fact]
        public void GetToken()
        {
            var url = $"{BaseAdfsUrl}/adfs/oauth2/token";
            var reqObj = $"grant_type=authorization_code&client_id={ClientId}&redirect_uri=http://localhost&code=code";
            _apiClient.Post<AdfsAuthenticator.OAuthTokenResponse>(url, reqObj).Returns(new AdfsAuthenticator.OAuthTokenResponse
            {
                AccessToken = "Access",
                ExpiresIn = 60,
                RefreshToken = "Ref",
                TokenType = "Type"
            });
            var r = _subject.GetToken("code", "http://localhost");

            Assert.Equal(ApiClientOptions.ContentTypes.Form, _apiClient.Options.ContentType);
            Assert.True(_apiClient.Options.IgnoreServerCertificateValidation);
            Assert.Equal(ApiClientOptions.ContentTypes.Form, _apiClient.Options.ContentType);
            Assert.Equal("Access", r.AccessToken);
        }

        [Fact]
        public void Refresh()
        {
            var url = $"{BaseAdfsUrl}/adfs/oauth2/token";
            var reqObj = $"grant_type=refresh_token&client_id={ClientId}&refresh_token=refresh";
            _apiClient.Post<AdfsAuthenticator.OAuthTokenResponse>(url, reqObj).Returns(new AdfsAuthenticator.OAuthTokenResponse
            {
                AccessToken = "Access",
                ExpiresIn = 60,
                RefreshToken = "Ref",
                TokenType = "Type"
            });
            var r = _subject.Refresh("refresh");

            Assert.Equal(ApiClientOptions.ContentTypes.Form, _apiClient.Options.ContentType);
            Assert.True(_apiClient.Options.IgnoreServerCertificateValidation);
            Assert.Equal(ApiClientOptions.ContentTypes.Form, _apiClient.Options.ContentType);
            Assert.Equal("Access", r.AccessToken);
            Assert.Equal("Ref", r.RefreshToken);
        }

        [Fact]
        public void ShouldReturnLoginUrl()
        {
            Assert.Equal($"{BaseAdfsUrl}/adfs/oauth2/authorize?response_type=code&resource={RelyingPartyAddress}&client_id={ClientId}", _subject.GetLoginUrl());
        }

        [Fact]
        public void ShouldReturnLoginUrlWithTrailngSlash()
        {
            _adfsSettingsResolver.Resolve().Returns(_ => new AdfsSettings(BaseAdfsUrl + "/", ClientId, RelyingPartyAddress, Certificate, ReturnUrls));
            Assert.Equal($"{BaseAdfsUrl}/adfs/oauth2/authorize?response_type=code&resource={RelyingPartyAddress}&client_id={ClientId}", _subject.GetLoginUrl());
        }

        [Fact]
        public void ShouldReturnLogoutUrl()
        {
            Assert.Equal($"{BaseAdfsUrl}/adfs/ls/?wa=wsignout1.0", _subject.GetLogoutUrl(string.Empty));

            var redirectUri = "http://localhost";
            Assert.Equal($"{BaseAdfsUrl}/adfs/ls/?wa=wsignout1.0&wreply={redirectUri}", _subject.GetLogoutUrl(redirectUri));
        }
    }
}