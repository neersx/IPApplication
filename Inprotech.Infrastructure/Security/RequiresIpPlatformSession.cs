using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using Autofac.Integration.WebApi;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure.Security
{
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
    public class RequiresIpPlatformSessionAttribute : Attribute
    {
    }

    public class RequiresIpPlatformSessionFilter : IAutofacAuthorizationFilter
    {
        readonly IIpPlatformSession _session;
        readonly IAccessTokenCache _accessTokenCache;
        readonly IAuthSettings _settings;
        readonly ILogger<RequiresIpPlatformSessionFilter> _logger;

        public RequiresIpPlatformSessionFilter(IIpPlatformSession session, IAccessTokenCache accessTokenCache, IAuthSettings settings, ILogger<RequiresIpPlatformSessionFilter> logger)
        {
            _session = session;
            _accessTokenCache = accessTokenCache;
            _settings = settings;
            _logger = logger;
        }

        public async Task OnAuthorizationAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            var action = actionContext.ActionDescriptor.GetCustomAttributes<RequiresIpPlatformSessionAttribute>();
            var controller = actionContext.ControllerContext.ControllerDescriptor.GetCustomAttributes<RequiresIpPlatformSessionAttribute>();

            if (action.Any() || controller.Any())
            {
                if (!_session.IsActive(actionContext.Request))
                {
                    actionContext.Response = actionContext.Request.CreateErrorResponse(HttpStatusCode.Forbidden, "Requires IP Platform Session");
                }
                else
                {
                    try
                    {
                        var accessToken = await _session.GetUserAccessToken(actionContext.Request);
                        _accessTokenCache.Store(accessToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.Exception(ex);
                        var response = actionContext.Request.CreateErrorResponse(HttpStatusCode.Unauthorized, "Invalid IP Platform Session");
                        actionContext.Response = response.WithExpiredCookie(_settings.SessionCookieName, _settings.SessionCookiePath, _settings.SessionCookieDomain);
                    }
                }
            }
        }
    }

    public interface IIpPlatformSession
    {
        bool IsActive(HttpRequestMessage request);
        Task<string> GetUserAccessToken(HttpRequestMessage request);
    }

    public class IpPlatformSession : IIpPlatformSession
    {
        readonly IAuthSettings _settings;
        readonly IUserIdentityAccessManager _userIdentityAccessManager;
        readonly ITokenRefresh _tokenRefresh;

        public IpPlatformSession(IAuthSettings settings, IUserIdentityAccessManager userIdentityAccessManager, ITokenRefresh tokenRefresh)
        {
            _settings = settings;
            _userIdentityAccessManager = userIdentityAccessManager;
            _tokenRefresh = tokenRefresh;
        }

        public bool IsActive(HttpRequestMessage request)
        {
            return request.ParseAuthCookie(_settings).AuthMode == AuthenticationModeKeys.Sso;
        }

        public async Task<string> GetUserAccessToken(HttpRequestMessage request)
        {
            var data = request.ParseAuthCookie(_settings);
            if (data.AuthMode != AuthenticationModeKeys.Sso)
                return null;

            var (r, _) = await _userIdentityAccessManager.GetSigninData(data.LogId, data.UserId, data.AuthMode);
            var ssoProviderResponse = _tokenRefresh.Refresh(r.AccessToken, r.RefreshToken, AuthenticationModeKeys.Sso);
            if (r.AccessToken != ssoProviderResponse.AccessToken || r.RefreshToken != ssoProviderResponse.RefreshToken)
            {
                r.AccessToken = ssoProviderResponse.AccessToken;
                r.RefreshToken = ssoProviderResponse.RefreshToken;
                await _userIdentityAccessManager.ExtendProviderSession(data.LogId, data.UserId, data.AuthMode, r);
            }

            return r.AccessToken;
        }
    }
}