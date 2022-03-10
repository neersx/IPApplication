using System;
using System.Data.Entity;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.External;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Microsoft.Rest;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v10
{
    public interface IAccessTokenManager
    {
        Task<bool> HasAccessToken(Uri loginEndpoint, string userName, string password);
        Task GetAccessToken(string userName, string code, string callBackUrl, IManageSettings.SiteDatabaseSettings setting);
        Task RefreshAccessToken(string userName, IManageSettings.SiteDatabaseSettings setting);
        Task SaveToken(CredentialTokens tokens, string userName);
        Task<CredentialTokens> GetToken(string userName);
        CredentialTokens GetStoredTokens();
        void SetStoredTokens(CredentialTokens token);
    }

    public class AccessTokenManager : IAccessTokenManager
    {
        readonly IDbContext _dbContext;
        readonly IIdentityBoundCryptoService _cryptoService;
        CredentialTokens _token;
        readonly ILogger<AccessTokenManager> _logger;

        public AccessTokenManager(IDbContext dbContext, IIdentityBoundCryptoService cryptoService, ILogger<AccessTokenManager> logger)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
            _logger = logger;
        }

        public async Task<bool> HasAccessToken(Uri loginEndpoint, string userName, string password)
        {
            var accessToken = await GetToken(userName);
            if (accessToken != null)
            {
                _token = accessToken;
            }
            return accessToken?.AccessToken != null;
        }

        public async Task GetAccessToken(string userName, string code, string callBackUrl, IManageSettings.SiteDatabaseSettings setting)
        {
            if (setting == null) throw new ArgumentNullException(nameof(setting));
            if (string.IsNullOrWhiteSpace(code)) throw new ArgumentNullException(nameof(code));
            if (string.IsNullOrWhiteSpace(callBackUrl)) throw new ArgumentNullException(nameof(callBackUrl));
            var grantType = "authorization_code";
            var payload = $"grant_type={grantType}&code={code}&client_secret={setting.ClientSecret}&client_id={setting.ClientId}&redirect_uri={Uri.EscapeDataString(callBackUrl)}";
            await CallAccessTokenUrl(userName, setting, payload);
        }

        public async Task RefreshAccessToken(string userName, IManageSettings.SiteDatabaseSettings setting)
        {
            var accessToken = await GetToken(userName);
            if (accessToken == null || !accessToken.OAuth2 || string.IsNullOrWhiteSpace(accessToken.RefreshToken))
            {
                throw new OAuth2TokenException();
            }

            var grantType = "refresh_token";
            var payload = $"grant_type={grantType}&client_secret={setting.ClientSecret}&client_id={setting.ClientId}&refresh_token={HttpUtility.UrlEncode(accessToken.RefreshToken)}";
            try
            {
                await CallAccessTokenUrl(userName, setting, payload);
            }
            catch (HttpRequestException)
            {
                throw new OAuth2TokenException();
            }
        }

        async Task CallAccessTokenUrl(string userName, IManageSettings.SiteDatabaseSettings setting, string payload)
        {
            var accessTokenUri = new Uri(setting.AccessTokenUrl);
            using (var handler = new HttpClientHandler { UseCookies = false })
            using (var client = new HttpClient(handler) { BaseAddress = accessTokenUri })
            using (var request = new HttpRequestMessage(HttpMethod.Post, accessTokenUri))
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();
                request.Content = new StringContent(payload, Encoding.UTF8, "application/x-www-form-urlencoded");
                using (var response = await client.SendAsync(request, HttpCompletionOption.ResponseContentRead))
                {
                    ServiceClientTracing.ReceiveResponse(invocationId, response);
                    if (response.Content != null)
                    {
                        var statusCode = response.StatusCode;
                        var jsonData = await response.Content.ReadAsStringAsync();

                        if (!response.IsSuccessStatusCode)
                        {
                            ServiceClientTracing.Error(invocationId,
                                                       new HttpOperationException(
                                                                                  $"Operation returned an invalid status code '{response.StatusCode}'")
                                                       {
                                                           Request = new HttpRequestMessageWrapper(request, null),
                                                           Response = new HttpResponseMessageWrapper(response, jsonData)
                                                       });

                            var error = JObject.Parse(jsonData);
                            throw new HttpRequestException(
                                                           $"Response status code does not indicate success: {(int)statusCode} ({response.ReasonPhrase}) - {error["message"]}");
                        }

                        var tokens = JsonConvert.DeserializeObject<OAuthTokenResponse>(jsonData);

                        if (string.IsNullOrWhiteSpace(tokens.AccessToken)) throw new ArgumentNullException(nameof(tokens.AccessToken));

                        _token = new CredentialTokens
                        {
                            AccessToken = tokens.AccessToken,
                            RefreshToken = tokens.RefreshToken,
                            OAuth2 = true
                        };

                        await SaveToken(_token, userName);

                        ServiceClientTracing.Exit(invocationId, jsonData);
                    }
                }
            }
        }

        public async Task SaveToken(CredentialTokens tokens, string userName)
        {
            var user = _dbContext.Set<User>().SingleOrDefault(_ => _.UserName == userName);
            if (user == null) return;
            var externalCredentials = _dbContext.Set<ExternalCredentials>().SingleOrDefault(v => v.User.Id == user.Id && v.ProviderName == KnownExternalSettings.IManage);

            if (externalCredentials == null)
            {
                _dbContext.Set<ExternalCredentials>()
                          .Add(new ExternalCredentials(user, user.UserName, _cryptoService.Encrypt(JObject.FromObject(tokens).ToString()), KnownExternalSettings.IManage));
            }
            else
            {
                externalCredentials.Password = _cryptoService.Encrypt(JObject.FromObject(tokens).ToString());
            }

            await _dbContext.SaveChangesAsync();
        }

        public async Task<CredentialTokens> GetToken(string userName)
        {
            try
            {
                var user = await _dbContext.Set<User>().SingleOrDefaultAsync(_ => _.UserName == userName);

                if (user == null) return null;
                var externalCredentials = _dbContext.Set<ExternalCredentials>().SingleOrDefault(v => v.User.Id == user.Id && v.ProviderName == KnownExternalSettings.IManage);

                return externalCredentials != null ? JsonConvert.DeserializeObject<CredentialTokens>(_cryptoService.Decrypt(externalCredentials.Password)) : null;
            }
            catch (Exception ex)
            {
                _logger.Exception(ex);
                return null;
            }
        }

        public CredentialTokens GetStoredTokens()
        {
            return _token;
        }

        public void SetStoredTokens(CredentialTokens token)
        {
            _token = token;
        }
    }
}
