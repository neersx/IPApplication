using System;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using CPA.SingleSignOn.Client.Services;
using Inprotech.Contracts;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Security
{
    [AllowAnonymous]
    public class SignOutController : ApiController
    {
        readonly IAdfsAuthenticator _adfsAuthenticator;
        readonly ILogger<SignOutController> _logger;
        readonly IAuthSettings _settings;
        readonly ITokenManagementService _tokenManagementService;
        readonly IUserIdentityAccessManager _userIdentityAccessManager;

        public SignOutController(IAuthSettings settings,
                                 ITokenManagementService tokenManagementService,
                                 IUserIdentityAccessManager userIdentityAccessManager,
                                 IAdfsAuthenticator adfsAuthenticator,
                                 ILogger<SignOutController> logger)
        {
            _settings = settings;
            _tokenManagementService = tokenManagementService;
            _userIdentityAccessManager = userIdentityAccessManager;
            _adfsAuthenticator = adfsAuthenticator;
            _logger = logger;
        }

        [NoEnrichment]
        public async Task<HttpResponseMessage> Get(string source = null)
        {
            var currentData = Request.ParseAuthCookieDataWithExpiry(_settings);
            var isOldWeb = source == "InprotechWeb";

            var b = new UriBuilder(
                                   Request.RequestUri.Scheme,
                                   Request.RequestUri.Host,
                                   Request.RequestUri.Port,
                                   _settings.SignInUrl);

            if (isOldWeb)
                b.Fragment = "/?goto=" + InprotechDefaultUrl();

            var redirectUri = b.Uri;

            if (currentData.data != null)
            {
                await _userIdentityAccessManager.EndSession(currentData.data.LogId);
                if (_settings.SsoEnabled && currentData.data.AuthMode == AuthenticationModeKeys.Sso)
                {
                    var signOutPath = $"{_tokenManagementService.GetLogoutUrl()}?resumeUrl={HttpUtility.UrlEncode(redirectUri.ToString())}";
                    redirectUri = new Uri(signOutPath);
                    await RevokeSession(currentData.data.LogId, currentData.data.UserId);
                }
                else if (_settings.AdfsEnabled && currentData.data.AuthMode == AuthenticationModeKeys.Adfs)
                {
                    redirectUri = new Uri(_adfsAuthenticator.GetLogoutUrl(HttpUtility.UrlEncode(redirectUri.ToString())));
                }
            }

            HttpResponseMessage response = Request.CreateErrorResponse(isOldWeb ? HttpStatusCode.OK : HttpStatusCode.Redirect, string.Empty)
                                                  .WithExpiredCookie(_settings.SessionCookieName, _settings.SessionCookiePath, _settings.SessionCookieDomain);

            response.Headers.Location = redirectUri;

            return response;
        }

        async Task RevokeSession(long logId, int identityId)
        {
            try
            {
                var (identityAccessData, _) = await _userIdentityAccessManager.GetSigninData(logId, identityId, AuthenticationModeKeys.Sso);
                if (!string.IsNullOrWhiteSpace(identityAccessData?.SessionId) && !string.IsNullOrWhiteSpace(identityAccessData.AccessToken))
                {
                    _tokenManagementService.Revoke(identityAccessData.AccessToken, identityAccessData.SessionId);
                }
            }
            catch (Exception e)
            {
                //The revoke may throw exception, if session is invalidated from other application.
                //Swallow this exception, log it only for administrator's information
                _logger.Warning("Session revoke failed: " + e.Message);
            }
        }

        UriBuilder InprotechDefaultUrl()
        {
            var requestUrl = Request.RequestUri;
            return new UriBuilder(
                                  requestUrl.Scheme,
                                  requestUrl.Host,
                                  requestUrl.Port,
                                  _settings.ParentPath + "/default.aspx");
        }
    }
}