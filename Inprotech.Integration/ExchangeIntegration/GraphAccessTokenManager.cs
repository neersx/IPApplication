using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.External;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.ExchangeIntegration
{
    public interface IGraphAccessTokenManager
    {
        Task<bool> GetAccessTokenAsync(GraphMessage message, string accessCode);
        Task<CredentialTokens> GetStoredTokenAsync(int userId);
        Task<string> PreparedScopeFromSettings(ExchangeConfigurationSettings settings);
        Task<bool> RefreshAccessToken(int userId, ExchangeConfigurationSettings setting);
    }

    public class GraphAccessTokenManager : IGraphAccessTokenManager
    {
        readonly IAppSettings _appSettings;
        readonly IIdentityBoundCryptoService _cryptoService;
        readonly IDbContext _dbContext;
        readonly IBackgroundProcessLogger<IGraphAccessTokenManager> _logger;

        public GraphAccessTokenManager(IDbContext dbContext,
                                       IIdentityBoundCryptoService cryptoService,
                                       IBackgroundProcessLogger<IGraphAccessTokenManager> logger,
                                       IAppSettings appSettings
        )
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
            _logger = logger;
            _appSettings = appSettings;
        }

        public async Task<CredentialTokens> GetStoredTokenAsync(int userId)
        {
            try
            {
                var user = await _dbContext.Set<User>().SingleOrDefaultAsync(_ => _.Id == userId);

                if (user == null) return null;
                var externalCredentials = _dbContext.Set<ExternalCredentials>().SingleOrDefault(v => v.User.Id == user.Id && v.ProviderName == KnownExternalSettings.ExchangeSetting);

                return externalCredentials != null ? JsonConvert.DeserializeObject<CredentialTokens>(_cryptoService.Decrypt(externalCredentials.Password)) : null;
            }
            catch (Exception ex)
            {
                _logger.Exception(ex);
                return null;
            }
        }

        public async Task<bool> GetAccessTokenAsync(GraphMessage message, string accessCode)
        {
            var param = new List<KeyValuePair<string, string>>
            {
                new KeyValuePair<string, string>("client_id", message.GraphSettings.ClientId),
                new KeyValuePair<string, string>("code", accessCode),
                new KeyValuePair<string, string>("redirect_uri", message.CallBackUrl),
                new KeyValuePair<string, string>("grant_type", "authorization_code"),
                new KeyValuePair<string, string>("scope", message.Scope),
                new KeyValuePair<string, string>("client_secret", message.GraphSettings.ClientSecret)
            };

            if (!await RequestAccessTokenAsync(message.UserId, message.GraphSettings, param)) return false;
            return true;
        }

        public async Task<bool> RefreshAccessToken(int userId, ExchangeConfigurationSettings setting)
        {
            var accessToken = await GetStoredTokenAsync(userId);
            if (accessToken == null || !accessToken.OAuth2 || string.IsNullOrWhiteSpace(accessToken.RefreshToken)) return false;

            var param = new List<KeyValuePair<string, string>>
            {
                new KeyValuePair<string, string>("grant_type", "refresh_token"),
                new KeyValuePair<string, string>("client_id", setting.ExchangeGraph.ClientId),
                new KeyValuePair<string, string>("scope", await PreparedScopeFromSettings(setting)),
                new KeyValuePair<string, string>("refresh_token", accessToken.RefreshToken),
                new KeyValuePair<string, string>("client_secret", setting.ExchangeGraph.ClientSecret)
            };

            if (!await RequestAccessTokenAsync(userId, setting.ExchangeGraph, param)) return false;
            return true;
        }

        public Task<string> PreparedScopeFromSettings(ExchangeConfigurationSettings settings)
        {
            var scope = new StringBuilder();
            if (!settings.RefreshTokenNotRequired)
            {
                scope.Append("offline_access ");
            }

            if (settings.IsReminderEnabled)
            {
                scope.Append($"{_appSettings.GraphApiUrl}/Calendars.ReadWrite ");
                scope.Append($"{_appSettings.GraphApiUrl}/Tasks.ReadWrite ");
            }

            if (settings.IsBillFinalisationEnabled || settings.IsDraftEmailEnabled)
            {
                scope.Append($"{_appSettings.GraphApiUrl}/Mail.ReadWrite ");
            }

            return Task.FromResult(scope.ToString());
        }

        async Task SaveTokenAsync(CredentialTokens tokens, int userId)
        {
            var user = _dbContext.Set<User>().SingleOrDefault(_ => _.Id == userId);
            if (user == null) return;
            var externalCredentials = _dbContext.Set<ExternalCredentials>().SingleOrDefault(v => v.User.Id == user.Id && v.ProviderName == KnownExternalSettings.ExchangeSetting);
            if (externalCredentials == null)
            {
                _dbContext.Set<ExternalCredentials>()
                          .Add(new ExternalCredentials(user, user.UserName, _cryptoService.Encrypt(JObject.FromObject(tokens).ToString()), KnownExternalSettings.ExchangeSetting));
            }
            else
            {
                externalCredentials.Password = _cryptoService.Encrypt(JObject.FromObject(tokens).ToString());
            }

            await _dbContext.SaveChangesAsync();
        }

        async Task<bool> RequestAccessTokenAsync(int userId, ExchangeGraph graphSetting, IEnumerable<KeyValuePair<string, string>> param)
        {
            var hc = new HttpClient();
            var content = new FormUrlEncodedContent(param);
            var hrm = await hc.PostAsync(string.Format(_appSettings.GraphAuthUrl + "/token", graphSetting.TenantId), content);
            if (!hrm.IsSuccessStatusCode) return false;
            var response = await hrm.Content.ReadAsAsync<OAuthTokenResponse>();
            var token = new CredentialTokens
            {
                AccessToken = response.AccessToken,
                RefreshToken = response.RefreshToken,
                OAuth2 = true
            };
            await SaveTokenAsync(token, userId);
            return true;
        }
    }
}