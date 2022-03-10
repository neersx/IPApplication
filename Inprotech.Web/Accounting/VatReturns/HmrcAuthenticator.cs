using System;
using System.Net;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Accounting.VatReturns
{
    public interface IHmrcAuthenticator
    {
        Task<dynamic> GetToken(string authenticationCode, string vrn);
        Task<HttpWebResponse> GetAuthCode(string stateId);
        Task<AuthToken> RefreshToken(string refreshToken, string vrn);
    }

    public class HmrcAuthenticator : IHmrcAuthenticator
    {
        const string AuthorizeUrl = "/oauth/authorize";
        const string TokenUrl = "/oauth/token";
        readonly IApiClient _apiClient;
        readonly IHmrcSettingsResolver _settings;
        readonly IHmrcTokenResolver _hmrcTokenResolver;

        public HmrcAuthenticator(IApiClient apiClient, IHmrcSettingsResolver settings, IHmrcTokenResolver hmrcTokenResolver)
        {
            _apiClient = apiClient;
            _settings = settings;
            _hmrcTokenResolver = hmrcTokenResolver;
        }

        public async Task<HttpWebResponse> GetAuthCode(string stateId)
        {
            var config = _settings.Resolve();
            var requestParams = $"?response_type=code&scope=read:vat+write:vat&state={stateId}&client_id={config.ClientId}&redirect_uri={Uri.EscapeDataString(config.RedirectUri)}";
            return await _apiClient.GetAsync(config.BaseUrl + AuthorizeUrl + requestParams);
        }

        public async Task<dynamic> GetToken(string authenticationCode, string vrn)
        {
            var config = _settings.Resolve();
            var reqObj = $"grant_type=authorization_code&code={authenticationCode}&client_secret={config.ClientSecret}&client_id={config.ClientId}&redirect_uri={Uri.EscapeDataString(config.RedirectUri)}";
            var parsed = await Post(config.BaseUrl + TokenUrl, reqObj);
            _hmrcTokenResolver.SaveTokens(new HmrcTokens { AccessToken = parsed.AccessToken, RefreshToken = parsed.RefreshToken }, vrn);
            return new
                   {
                       parsed.AccessToken,
                       parsed.RefreshToken,
                       parsed.ExpiresIn,
                       parsed.TokenType
                   };
        }

        public async Task<AuthToken> RefreshToken(string refreshToken, string vrn)
        {
            var config = _settings.Resolve();
            var reqObj = $"grant_type=refresh_token&refresh_token={refreshToken}&client_secret={config.ClientSecret}&client_id={config.ClientId}";
            var parsed = await Post(config.BaseUrl + TokenUrl, reqObj);
            _hmrcTokenResolver.SaveTokens(new HmrcTokens { AccessToken = parsed.AccessToken, RefreshToken = parsed.RefreshToken }, vrn);
            return new AuthToken
                   {
                       AccessToken = parsed.AccessToken,
                       RefreshToken = parsed.RefreshToken,
                       ExpiresIn = parsed.ExpiresIn,
                       TokenType = parsed.TokenType
                   };
        }

        async Task<OAuthTokenResponse> Post(string apiEndpoint, string req)
        {
            _apiClient.Options.ContentType = ApiClientOptions.ContentTypes.Form;
            return await _apiClient.PostAsync<OAuthTokenResponse>(apiEndpoint, req);
        }

    }
}