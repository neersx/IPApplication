using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.DmsIntegration.Component.iManage.v10;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Messages;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.DocumentManagement
{
    [RoutePrefix("api/dms")]
    public class DmsAuthRedirectController : ApiController
    {
        static readonly ConcurrentDictionary<string, DmsMessage> LifeTimeDictionaryToken = new ConcurrentDictionary<string, DmsMessage>();

        static readonly ConcurrentDictionary<string, IEnumerable<IManageSettings.SiteDatabaseSettings>> Settings = new ConcurrentDictionary<string, IEnumerable<IManageSettings.SiteDatabaseSettings>>();
        readonly IAccessTokenManager _accessTokenManager;
        readonly IBus _bus;
        readonly IDmsSettingsProvider _dmsSettingsProvider;
        readonly ISecurityContext _securityContext;
        readonly IUrlTester _urlTester;

        public DmsAuthRedirectController(IBus bus, ISecurityContext securityContext, IDmsSettingsProvider dmsSettingsProvider, IAccessTokenManager accessTokenManager, IUrlTester urlTester)
        {
            _bus = bus;
            _securityContext = securityContext;
            _dmsSettingsProvider = dmsSettingsProvider;
            _accessTokenManager = accessTokenManager;
            _urlTester = urlTester;
        }

        [HttpPost]
        [NoEnrichment]
        [Authorize]
        [Route("settings")]
        public void StoreSettings(string connectionId, [FromBody] IManageSettings.SiteDatabaseSettings[] settings)
        {
            Settings.TryAdd(connectionId, settings);
        }

        [HttpGet]
        [NoEnrichment]
        [Authorize]
        [Route("authorize/{connectionId}")]
        public async Task<IHttpActionResult> Authorize(string connectionId)
        {
            Settings.TryGetValue(connectionId, out var settings);
            settings = settings ?? await _dmsSettingsProvider.OAuth2Setting();
            var userName = _securityContext.User.UserName;
            var userId = _securityContext.User.Id.ToString();

            var siteDatabaseSettings = settings as IManageSettings.SiteDatabaseSettings[] ?? settings.ToArray();
            return await TryDmsAuthAction(async () =>
            {
                if (settings == null || !siteDatabaseSettings.Any()) throw new ArgumentNullException(string.Empty);

                var setting = siteDatabaseSettings.First();
                var callBackUrl = setting.GetCallbackUrlOrThrow(Request);
                var guid = Guid.NewGuid().ToString();
                var message = new DmsMessage { UserId = userId, UserName = userName, ConnectionId = connectionId };
                LifeTimeDictionaryToken.AddOrUpdate(guid, message, (k, v) => message);

                var newRoute = $"{setting.AuthUrl}?response_type=code&state={guid}&client_id={setting.ClientId}&scope=user&redirect_uri={Uri.EscapeDataString(callBackUrl)}";
                return Redirect(newRoute);
            }, connectionId, userId);
        }

        async Task<IHttpActionResult> TryDmsAuthAction(Func<Task<IHttpActionResult>> a, string connectionId, string userId)
        {
            try
            {
                return await a();
            }
            catch
            {
                _bus.Publish(new SendMessageToClient
                {
                    ConnectionId = connectionId,
                    Topic = "dms.oauth2.login." + userId,
                    Data = new { status = "Failed", userId }
                });
                throw;
            }
        }

        [HttpGet]
        [Route("imanage/auth/redirect")]
        public async Task<IHttpActionResult> Token()
        {
            var parsed = HttpUtility.ParseQueryString(Request.RequestUri.Query);
            var stateId = parsed.Get("state");
            var code = parsed.Get("code");

            if (string.IsNullOrWhiteSpace(stateId) || string.IsNullOrWhiteSpace(code))
            {
                return BadRequest();
            }

            if (!LifeTimeDictionaryToken.TryGetValue(stateId, out var message)) throw new ArgumentException("Invalid Session Id");
            if (string.IsNullOrWhiteSpace(code)) throw new ArgumentNullException(nameof(code));

            Settings.TryGetValue(message.ConnectionId, out var settings);
            settings = settings ?? await _dmsSettingsProvider.OAuth2Setting();
            var siteDatabaseSettings = settings as IManageSettings.SiteDatabaseSettings[] ?? settings.ToArray();
            return await TryDmsAuthAction(async () =>
            {
                if (!siteDatabaseSettings.Any())
                {
                    throw new ArgumentNullException(nameof(siteDatabaseSettings));
                }

                var setting = siteDatabaseSettings.First();
                var callbackUrl = setting.GetCallbackUrlOrThrow(Request);

                await _accessTokenManager.GetAccessToken(message.UserName, code, callbackUrl, setting);

                _bus.Publish(new SendMessageToClient
                {
                    ConnectionId = message.ConnectionId,
                    Topic = "dms.oauth2.login." + message.UserId,
                    Data = new { status = "Complete", message.UserId }
                });

                LifeTimeDictionaryToken.TryRemove(stateId, out _);

                return Redirect(new Uri(GetRedirectRoute()));
            }, message.ConnectionId, message.UserId);
        }

        string GetRedirectRoute()
        {
            var newRoute = Request.RequestUri.ReplaceStartingFromSegment("api", $"{Uri.EscapeUriString("signin/redirect/integration")}");
            return newRoute.ToString();
        }
    }

    public class DmsMessage
    {
        public string UserId { get; set; }
        public string UserName { get; set; }
        public string ConnectionId { get; set; }
    }
}