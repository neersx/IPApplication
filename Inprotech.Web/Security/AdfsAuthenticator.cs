using System;
using System.Globalization;
using System.IdentityModel.Tokens;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography.X509Certificates;
using System.Web;
using CPA.SingleSignOn.Client.Models;
using Inprotech.Infrastructure.Web;
using Newtonsoft.Json;

namespace Inprotech.Web.Security
{
    public interface IAdfsAuthenticator
    {
        string GetLoginUrl();
        string GetLogoutUrl(string redirectUrl);
        SSOProviderResponse GetToken(string code, string redirectUri);
        SSOProviderResponse Refresh(string refreshToken);
        ClaimsPrincipal ValidateToPrincipal(string accessToken);
        bool GetCallbackUri(string leftPart, out string redirectUri);
    }

    internal class AdfsAuthenticator : IAdfsAuthenticator
    {
        readonly IAdfsSettingsResolver _adfsSettingsResolver;
        readonly IApiClient _apiClient;
        AdfsSettings _settings;

        public AdfsAuthenticator(IAdfsSettingsResolver adfsSettingsResolver, IApiClient apiClient)
        {
            _adfsSettingsResolver = adfsSettingsResolver;
            _apiClient = apiClient;
        }

        AdfsSettings Settings => _settings ??= _adfsSettingsResolver.Resolve();

        Uri AdfsUrl => new (Settings.AdfsUrl);

        string RelyingPartyAddress => HttpUtility.UrlEncode(Settings.RelyingPartyAddress);

        Uri AuthorizeUrl => new (AdfsUrl, $"adfs/oauth2/authorize?response_type=code&resource={RelyingPartyAddress}&client_id={Settings.ClientId}");

        Uri LogoutUrl => new (AdfsUrl, "adfs/ls/?wa=wsignout1.0");

        Uri TokenUrl => new (AdfsUrl, "adfs/oauth2/token");

        public string GetLoginUrl()
        {
            return AuthorizeUrl.ToString();
        }

        public string GetLogoutUrl(string redirectUrl)
        {
            var signoutUrl = LogoutUrl.ToString();
            if (!string.IsNullOrEmpty(redirectUrl))
            {
                signoutUrl += $"&wreply={redirectUrl}";
            }

            return signoutUrl;
        }

        public SSOProviderResponse GetToken(string code, string redirectUri)
        {
            var reqObj = $"grant_type=authorization_code&client_id={Settings.ClientId}&redirect_uri={redirectUri}&code={code}";
            var parsed = Post(TokenUrl.ToString(), reqObj);
            return new SSOProviderResponse
            {
                AccessToken = parsed.AccessToken,
                RefreshToken = parsed.RefreshToken,
                ExpiresIn = parsed.ExpiresIn,
                TokenType = parsed.TokenType
            };
        }

        public SSOProviderResponse Refresh(string refreshToken)
        {
            var reqObj = $"grant_type=refresh_token&client_id={Settings.ClientId}&refresh_token={refreshToken}";
            var parsed = Post(TokenUrl.ToString(), reqObj);
            return new SSOProviderResponse
            {
                AccessToken = parsed.AccessToken,
                RefreshToken = parsed.RefreshToken ?? refreshToken,
                ExpiresIn = parsed.ExpiresIn,
                TokenType = parsed.TokenType
            };
        }

        public ClaimsPrincipal ValidateToPrincipal(string accessToken)
        {
            var validationParameters = GetTokenValidationParameters();
            SecurityToken validatedToken;
            var principal = new JwtSecurityTokenHandler().ValidateToken(accessToken, validationParameters, out validatedToken);
            return principal;
        }

        public bool GetCallbackUri(string leftPart, out string redirectUri)
        {
            leftPart = leftPart.Substring(0, leftPart.LastIndexOf('/'));
            redirectUri = Settings.RedirectUrls.SingleOrDefault(_ => _.StartsWith(leftPart, true, CultureInfo.InvariantCulture));
            if (string.IsNullOrWhiteSpace(redirectUri) || !redirectUri.Replace("/", string.Empty).EndsWith(Urls.AdfsReturn, StringComparison.InvariantCultureIgnoreCase))
            {
                return false;
            }

            return true;
        }

        OAuthTokenResponse Post(string apiEndpoint, string req)
        {
            _apiClient.Options.ContentType = ApiClientOptions.ContentTypes.Form;
            _apiClient.Options.IgnoreServerCertificateValidation = true;
            return _apiClient.Post<OAuthTokenResponse>(apiEndpoint, req);
        }

        TokenValidationParameters GetTokenValidationParameters()
        {
            var certificate = new X509Certificate2(Convert.FromBase64String(Settings.Certificate));
            var x509SecurityToken = new X509SecurityToken(certificate);
            return new TokenValidationParameters
            {
                RequireSignedTokens = true,
                IssuerSigningToken = x509SecurityToken,
                RequireExpirationTime = true,
                ValidateAudience = false,
                ValidateIssuer = false
            };
        }

        // ReSharper disable once ClassNeverInstantiated.Local
        public class OAuthTokenResponse
        {
            [JsonProperty("token_type")]
            public string TokenType { get; set; }

            [JsonProperty("expires_in")]
            public int ExpiresIn { get; set; }

            [JsonProperty("refresh_token")]
            public string RefreshToken { get; set; }

            [JsonProperty("access_token")]
            public string AccessToken { get; set; }
        }
    }
}