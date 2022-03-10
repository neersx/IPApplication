using System;
using System.Collections.Concurrent;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Integration;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.Web.DocumentManagement;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Messages;

namespace Inprotech.Web.ExchangeIntegration
{
    [RoutePrefix("api/graph")]
    public class GraphAuthRedirectController : ApiController
    {
        static readonly ConcurrentDictionary<string, GraphMessage> LifeTimeDictionaryToken = new ConcurrentDictionary<string, GraphMessage>();
        readonly IAppSettings _appSettings;
        readonly IBus _bus;
        readonly ExchangeIntegrationController _exchangeIntegrationController;
        readonly IGraphAccessTokenManager _graphAccessTokenManager;
        readonly IGraphNotification _graphNotification;
        readonly IGraphTaskIdCache _graphTaskIdCache;
        readonly ILogger<GraphAuthRedirectController> _logger;
        readonly ISecurityContext _securityContext;
        readonly IExchangeIntegrationSettings _settings;
        readonly string _topic = "graph.oauth2.login.{0}";
        readonly IUrlTester _urlTester;

        public GraphAuthRedirectController(IBus bus,
                                           ISecurityContext securityContext,
                                           IExchangeIntegrationSettings settings,
                                           IGraphAccessTokenManager graphAccessTokenManager,
                                           IUrlTester urlTester,
                                           IGraphNotification graphNotification,
                                           ExchangeIntegrationController exchangeIntegrationController,
                                           IAppSettings appSettings,
                                           ILogger<GraphAuthRedirectController> logger,
                                           IGraphTaskIdCache graphTaskIdCache
        )
        {
            _bus = bus;
            _securityContext = securityContext;
            _settings = settings;
            _graphAccessTokenManager = graphAccessTokenManager;
            _urlTester = urlTester;
            _graphNotification = graphNotification;
            _exchangeIntegrationController = exchangeIntegrationController;
            _appSettings = appSettings;
            _logger = logger;
            _graphTaskIdCache = graphTaskIdCache;
        }

        [HttpGet]
        [NoEnrichment]
        [Authorize]
        [Route("authorize/{connectionId}/{processId}")]
        public async Task<IHttpActionResult> Authorize(string connectionId, int processId)
        {
            var setting = _settings.Resolve();
            var userId = _securityContext.User.Id;

            return await TryAuthAction(async () =>
            {
                var callBackUrl = Request.RequestUri.ReplaceStartingFromSegment("api", $"{Uri.EscapeUriString("api/graph/auth/redirect")}").ToString();
                var scope = await _graphAccessTokenManager.PreparedScopeFromSettings(setting);
                var guid = Guid.NewGuid().ToString();

                var message = new GraphMessage
                {
                    UserId = userId,
                    ConnectionId = connectionId,
                    Scope = scope,
                    CallBackUrl = callBackUrl,
                    BackgroundProcessId = processId,
                    GraphSettings = setting.ExchangeGraph
                };
                LifeTimeDictionaryToken.AddOrUpdate(guid, message, (k, v) => message);

                await _urlTester.TestAuthorizationUrl($"{callBackUrl}?state=ping", HttpMethod.Get);

                var authUrl = string.Format(_appSettings.GraphAuthUrl + "/authorize", setting.ExchangeGraph.TenantId);
                var newRoute = $"{authUrl}?response_type=code&state={guid}&client_id={setting.ExchangeGraph.ClientId}&tenant={setting.ExchangeGraph.TenantId}&redirect_uri={Uri.EscapeDataString(callBackUrl)}&response_mode=query&scope={scope}" + (!setting.SupressConsentPrompt ? "&prompt=consent" : string.Empty);
                var testRoute = $"{authUrl}?response_type=code&state=ping&client_id={setting.ExchangeGraph.ClientId}&tenant={setting.ExchangeGraph.TenantId}&redirect_uri={Uri.EscapeDataString($"{callBackUrl}")}&response_mode=query&scope={scope}" + (!setting.SupressConsentPrompt ? "&prompt=consent" : string.Empty);
                await _urlTester.TestAuthorizationUrl(testRoute, HttpMethod.Get);

                return Redirect(newRoute);
            }, connectionId, userId);
        }

        async Task<IHttpActionResult> TryAuthAction(Func<Task<IHttpActionResult>> a, string connectionId, int userId)
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
                    Topic = string.Format(_topic, userId),
                    Data = new {status = "Failed", userId, messageId = "exchangeIntegration.graph.authorizationProcessFailed"}
                });
                throw;
            }
        }

        [HttpGet]
        [Route("auth/redirect")]
        public async Task<IHttpActionResult> Token()
        {
            var parsed = HttpUtility.ParseQueryString(Request.RequestUri.Query);
            var stateId = parsed.Get("state");

            if (stateId == "ping")
            {
                return Ok();
            }

            var code = parsed.Get("code");
            var error = parsed.Get("error");
            var redirectRoute = Request.RequestUri.ReplaceStartingFromSegment("api", $"{Uri.EscapeUriString("signin/redirect/integration")}");
            if (!LifeTimeDictionaryToken.TryGetValue(stateId, out var message)) throw new ArgumentException("Invalid Session Id");

            if (!string.IsNullOrEmpty(error) || string.IsNullOrWhiteSpace(code))
            {
                NotifyFailedMessage(message, "exchangeIntegration.graph.authCodeNotAcquired");
                _logger.Trace("Failed acquiring access code", parsed);
                return Redirect(redirectRoute);
            }

            return await TryAuthAction(async () =>
            {
                var tokenAcquired = await _graphAccessTokenManager.GetAccessTokenAsync(message, code);
                if (tokenAcquired)
                {
                    await _graphNotification.DeleteAsync(message.UserId);
                    await _exchangeIntegrationController.ResetExchangeRequests(message.UserId);
                    await _graphTaskIdCache.Remove(message.UserId);

                    _bus.Publish(new SendMessageToClient
                    {
                        ConnectionId = message.ConnectionId,
                        Topic = string.Format(_topic, message.UserId),
                        Data = new {status = "Complete", message.UserId}
                    });
                }
                else
                {
                    NotifyFailedMessage(message, "exchangeIntegration.graph.accessTokenNotAcquired");
                    _logger.Trace("Failed acquiring access token");
                }

                LifeTimeDictionaryToken.TryRemove(stateId, out _);

                return Redirect(redirectRoute);
            }, message.ConnectionId, message.UserId);
        }

        void NotifyFailedMessage(GraphMessage message, string messageId)
        {
            _bus.Publish(new SendMessageToClient
            {
                ConnectionId = message.ConnectionId,
                Topic = string.Format(_topic, message.UserId),
                Data = new {status = "Failed", message.UserId, messageId}
            });
        }
    }
}