using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using CPA.SingleSignOn.Client;
using CPA.SingleSignOn.Client.Services;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseEnrichment.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Analytics;
using Inprotech.Web.Security.ResetPassword;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.Security.SingleSignOn;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Security
{
    [RoutePrefix(Urls.ApiSignIn)]
    public class SignInController : ApiController
    {
        readonly IAdfsAuthenticator _adfsAuthenticator;
        readonly IAuthSettings _authSettings;
        readonly ITwoFactorAuthVerify _authVerify;
        readonly IDbContext _dbContext;
        readonly ILicenseAuthorization _licenseAuthorization;
        readonly IUserAuditLogger<SignInController> _logger;
        readonly ISourceIpAddressResolver _sourceIpResolver;
        readonly IPrincipalUser _principalUser;
        readonly IResetPasswordHelper _resetPasswordHelper;
        readonly ISsoUserIdentifier _ssoUserIdentifier;
        readonly ITokenExtender _tokenExtender;
        readonly ITokenManagementService _tokenManagement;
        readonly ITokenValidationService _tokenValidation;
        readonly IUserIdentityAccessManager _userIdentityAccess;
        readonly IUserTwoFactorAuthPreference _userTwoFactorAuthPreference;
        readonly IUserValidation _userValidation;
        readonly IProductImprovementSettingsResolver _productImprovementSettingsResolver;

        public SignInController(IDbContext dbContext, IAuthSettings authSettings,
                                IUserValidation userValidation,
                                ILicenseAuthorization licenseAuthorization,
                                ITokenManagementService tokenManagement,
                                ITokenValidationService tokenValidation,
                                IUserIdentityAccessManager userIdentityAccess,
                                ISsoUserIdentifier ssoUserIdentifier,
                                IAdfsAuthenticator adfsAuthenticator,
                                ITokenExtender tokenExtender,
                                IPrincipalUser principalUser, IUserAuditLogger<SignInController> logger,
                                ISourceIpAddressResolver sourceIpResolver,
                                IUserTwoFactorAuthPreference userTwoFactorAuthPreference, ITwoFactorAuthVerify authVerify, IResetPasswordHelper resetPasswordHelper, IProductImprovementSettingsResolver productImprovementSettingsResolver)
        {
            _dbContext = dbContext;
            _authSettings = authSettings;
            _userValidation = userValidation;
            _licenseAuthorization = licenseAuthorization;
            _tokenManagement = tokenManagement;
            _tokenValidation = tokenValidation;
            _userIdentityAccess = userIdentityAccess;
            _ssoUserIdentifier = ssoUserIdentifier;
            _adfsAuthenticator = adfsAuthenticator;
            _tokenExtender = tokenExtender;
            _principalUser = principalUser;
            _logger = logger;
            _sourceIpResolver = sourceIpResolver;
            _userTwoFactorAuthPreference = userTwoFactorAuthPreference;
            _authVerify = authVerify;
            _resetPasswordHelper = resetPasswordHelper;
            _productImprovementSettingsResolver = productImprovementSettingsResolver;
        }

        [HttpPost]
        [NoEnrichment]
        [Route("")]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Forms)]
        public async Task<HttpResponseMessage> Post(JObject credentialsObject)
        {
            if (credentialsObject == null) throw new ArgumentNullException(nameof(credentialsObject));
            var credentials = credentialsObject.ToObject<SigninCredentials>();

            var username = credentials.Username;
            var user = _dbContext.Set<User>().SingleOrDefault(u => u.UserName == username);

            if (user == null)
            {
                _logger.Warning(credentials.Username + " | unauthorised-credentials", Request);
                return Request.CreateResponse(HttpStatusCode.OK, new SignInResponse { Status = "unauthorised-credentials" });
            }

            var authCookie = Request.ParseAuthCookieDataWithExpiry(_authSettings);
            var overwrittenTwoFactor = credentials.SessionResume && authCookie.data != null && authCookie.data.UserId == user.Id;
            var userNeeds2F = !overwrittenTwoFactor && _authSettings.TwoFactorAuthenticationEnabled(user.IsExternalUser);

            var validation = userNeeds2F
                ? await _userValidation.Validate(user, credentials.Password, credentials.Preference, credentials.Code)
                : await _userValidation.Validate(user, credentials.Password);

            if (!validation.Accepted)
            {
                _logger.Warning(credentials.Username + " | " + validation.FailReasonCode, Request);
                return Request.CreateResponse(HttpStatusCode.OK, validation);
            }

            if (userNeeds2F && string.IsNullOrWhiteSpace(credentials.Code) && credentials.Application != "OOB")
            {
                return await CodeRequiredRedirect(user, credentials.ReturnUrl, AuthenticationModeKeys.Forms, null, credentials.Application, credentials.Preference);
            }

            AuthorizationResponse authorization;
            if (!_licenseAuthorization.TryAuthorize(user, out authorization))
            {
                _logger.Warning(credentials.Username + " | " + authorization.FailReasonCode, Request);
                return Request.CreateResponse(HttpStatusCode.OK, authorization);
            }

            if (_userValidation.IsPasswordExpired(user))
            {
                var token = await _resetPasswordHelper.ResolveSecretKey(user);
                var redirectUrl = Request.RequestUri.ReplaceStartingFromSegment("apps", "apps/signin/#/reset-password?token=" + HttpUtility.UrlEncode(token));
                
                _logger.Warning(credentials.Username + " | password-expired", Request);
                return Request.CreateResponse(HttpStatusCode.OK, new SignInResponse
                {
                    Status = "resetPassword",
                    ReturnUrl = redirectUrl.ToString()
                });
            }

            return await SuccessRedirect(user, credentials.ReturnUrl, true, AuthenticationModeKeys.Forms, null, credentials.Application);
        }

        [HttpGet]
        [IncludeLocalisationResources("signin")]
        [Route("options")]
        public SignInOptions GetSignInOptions()
        {
            return new SignInOptions
            {
                ShowForms = _authSettings.FormsEnabled,
                ShowWindows = _authSettings.WindowsEnabled,
                ShowSso = _authSettings.SsoEnabled,
                ShowAdfs = _authSettings.AdfsEnabled,
                CookieConsent = _authSettings.CookieConsentSettings,
                FirmConsentedToUserStatistics = _productImprovementSettingsResolver.Resolve().UserUsageStatisticsConsented 
            };
        }

        [HttpGet]
        [NoEnrichment]
        [Route("initiateSso")]
        [HandleSsoException]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
        public HttpResponseMessage InitiateSso(string redirectUrl)
        {
            try
            {
                var leftPart = new Uri(Request.RequestUri.GetLeftPart(UriPartial.Path));

                var uri = new Uri(leftPart, $"{Urls.SsoReturn}?redirectUrl={HttpUtility.UrlEncode(redirectUrl)}");

                return Redirect(_tokenManagement.GetLoginUrl(), uri);
            }
            catch (Exception e)
            {
                throw new SsoException("SSO token error", e, SetErrorCode("server-error", redirectUrl));
            }
        }

        [HttpGet]
        [NoEnrichment]
        [Route("adfs")]
        [HandleSsoException]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Adfs)]
        public HttpResponseMessage Adfs(string redirectUrl)
        {
            try
            {
                string callbackUrl;
                var urlFound = _adfsAuthenticator.GetCallbackUri(Request.RequestUri.GetLeftPart(UriPartial.Path), out callbackUrl);
                if (!urlFound)
                {
                    throw new SsoException($"The URL scheme '{Request.RequestUri.ReplaceStartingFromSegment("apps", string.Empty).GetLeftPart(UriPartial.Path)}' does not match with any of the return urls registered in Inprotech", SetErrorCode("server-error", redirectUrl));
                }

                var uri = new Uri(new Uri(callbackUrl), $"?redirectUrl={HttpUtility.UrlEncode(redirectUrl)}");

                return Redirect(_adfsAuthenticator.GetLoginUrl(), uri);
            }
            catch (SsoException)
            {
                throw;
            }
            catch (Exception e)
            {
                throw new SsoException("ADFS Request error", e, SetErrorCode("server-error", redirectUrl));
            }
        }

        [HttpPost]
        [NoEnrichment]
        [Route("extendsso")]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
        public async Task<HttpResponseMessage> ExtendSso()
        {
            var cookieData = Request.ParseAuthCookie(_authSettings);
            (var shouldExtend, var tokenValid) = await _tokenExtender.ShouldExtend(cookieData);
            if (!tokenValid)
            {
                _logger.Warning("sso-extension-failure", Request);
                return Request.CreateResponse(HttpStatusCode.OK, new { Status = "failure" });
            }

            var response = Request.CreateResponse(HttpStatusCode.OK, new
            {
                Status = "success"
            });

            if (shouldExtend)
            {
                var user = _dbContext.Set<User>().Single(_ => _.Id == cookieData.UserId);
                response.WithAuthCookie(_authSettings, new AuthUser(user.UserName, user.Id, cookieData.AuthMode, cookieData.LogId));
            }

            return response;
        }

        [HttpGet]
        [NoEnrichment]
        [Route(Urls.SsoReturn)]
        [HandleSsoException]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
        public async Task<HttpResponseMessage> SsoReturn(string redirectUrl, string code)
        {
            try
            {
                var codeUrl = Request.RequestUri.AbsoluteUri.Split(new[] { "&code=", "?code=" }, StringSplitOptions.RemoveEmptyEntries)[0];
                var ssoProviderResponse = _tokenManagement.GetByCode(code, codeUrl);
                var claimsPrincipal = _tokenValidation.ValidateToPrincipal(ssoProviderResponse.AccessToken);
                var claimsIdentity = claimsPrincipal.Identity as ClaimsIdentity;

                User user;
                SsoUserLinkResultType emailVerificationResult;
                if (_ssoUserIdentifier.TryFindUser(claimsIdentity.GetGUK(), out user) && _ssoUserIdentifier.EnforceEmailValidity(claimsIdentity.GetEmail(), user, out emailVerificationResult) ||
                    _ssoUserIdentifier.TryLinkUserAuto(claimsIdentity.ToSsoIdentity(), out user, out emailVerificationResult))
                {
                    var userIdenityAccess = new UserIdentityAccessData(claimsIdentity.GetSessionId(), ssoProviderResponse.AccessToken, ssoProviderResponse.RefreshToken);
                    return await ValidateLicenseAndReturnSso(user, AuthenticationModeKeys.Sso, userIdenityAccess, redirectUrl);
                }

                var message = $"Result:{emailVerificationResult},The IP Platform user was correctly identified but the user is not linked to a corresponding unique user in Inprotech. Ensure that the email:{claimsIdentity.GetEmail()} is assigned to a user. The email must be assigned to a single Inprotech user";
                throw new SsoException(message, SetErrorCode("sso-error", redirectUrl));
            }
            catch (SsoException)
            {
                throw;
            }
            catch (Exception e)
            {
                throw new SsoException("Sso redirect error", e, SetErrorCode("server-error", redirectUrl));
            }
        }

        [HttpGet]
        [NoEnrichment]
        [Route(Urls.AdfsReturn)]
        [HandleSsoException]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Adfs)]
        public async Task<HttpResponseMessage> AdfsReturn(string redirectUrl, string code)
        {
            try
            {
                var codeUrl = Request.RequestUri.AbsoluteUri.Split(new[] { "&code=", "?code=" }, StringSplitOptions.RemoveEmptyEntries)[0];
                var ssoProviderResponse = _adfsAuthenticator.GetToken(code, HttpUtility.UrlEncode(codeUrl));
                var claimsPrincipal = _adfsAuthenticator.ValidateToPrincipal(ssoProviderResponse.AccessToken);

                if (IsRequestFromSetupProgram(redirectUrl))
                {
                    return new HttpResponseMessage(HttpStatusCode.OK)
                    {
                        Content = new StringContent("Adfs test is successfull")
                    };
                }

                var user = _principalUser.From(claimsPrincipal, ClaimTypes.WindowsAccountName);
                if (user != null)
                {
                    var userIdentityAccessData = new UserIdentityAccessData(null, null, ssoProviderResponse.RefreshToken);
                    return await ValidateLicenseAndReturnSso(user, AuthenticationModeKeys.Adfs, userIdentityAccessData, redirectUrl);
                }

                var identity = claimsPrincipal.Identity as ClaimsIdentity;
                var name = identity?.GetClaimValueString(ClaimTypes.WindowsAccountName);
                throw new SsoException($"The ADFS user was not found in Inprotech. You may need to assign the LoginId({name})to a valid user in Inprotech", SetErrorCode("adfs-error", redirectUrl));
            }
            catch (SsoException)
            {
                throw;
            }
            catch (Exception e)
            {
                if (IsRequestFromSetupProgram(redirectUrl))
                {
                    return new HttpResponseMessage(HttpStatusCode.OK)
                    {
                        Content = new StringContent("Token authorization failed. Make sure you are using a valid jwt certificate")
                    };
                }

                throw new SsoException("Sso redirect error", e, SetErrorCode("server-error", redirectUrl));
            }
        }

        [HttpPut]
        [NoEnrichment]
        [Authorize]
        [Route("ping")]
        public async Task<HttpResponseMessage> PingToCheckSessionValidity()
        {
            var cookieData = Request.ParseAuthCookie(_authSettings);
            if (cookieData != null)
            {
                if (new[] { AuthenticationModeKeys.Adfs, AuthenticationModeKeys.Sso }.Contains(cookieData.AuthMode))
                {
                    return await ExtendSso();
                }

                return Request.CreateResponse(HttpStatusCode.OK, new { Status = "success" });
            }

            return Request.CreateResponse(HttpStatusCode.OK, new { Status = "failure" });
        }

        async Task<HttpResponseMessage> CodeRequiredRedirect(User user, string redirectUrl, string authMode, UserIdentityAccessData logData, string application, string twoFactorMode)
        {
            var redirectTo = GetRedirectUrl(redirectUrl);

            var source = _sourceIpResolver.Resolve(Request);

            _userIdentityAccess.StartSession(user.Id, authMode, logData, application, source);
            await ExpireCurrentUserSessionIfExists();

            var resolvePreferredMethod = twoFactorMode;
            if (string.IsNullOrWhiteSpace(resolvePreferredMethod))
            {
                resolvePreferredMethod = await _userTwoFactorAuthPreference.ResolvePreferredMethod(user.Id);
            }

            return await TwoFactorAuthentiationRedirectResponse(user, resolvePreferredMethod, redirectTo);
        }

        async Task<HttpResponseMessage> SuccessRedirect(User user, string redirectUrl, bool json, string authMode, UserIdentityAccessData logData, string application)
        {
            var redirectTo = GetRedirectUrl(redirectUrl);

            var source = _sourceIpResolver.Resolve(Request);

            var logId = _userIdentityAccess.StartSession(user.Id, authMode, logData, application, source);
            await ExpireCurrentUserSessionIfExists();

            HttpResponseMessage response;
            if (json)
            {
                response = Request.CreateResponse(HttpStatusCode.OK, new SignInResponse
                {
                    Status = "success",
                    ReturnUrl = redirectTo.ToString()
                });
            }
            else
            {
                response = Request.CreateResponse(HttpStatusCode.Moved);
                response.Headers.Location = redirectTo;
            }

            return response.WithAuthCookie(_authSettings, new AuthUser(user.UserName, user.Id, authMode, logId));
        }

        Uri GetRedirectUrl(string redirectUrl)
        {
            return string.IsNullOrEmpty(redirectUrl)
                ? Request.RequestUri.ReplaceStartingFromSegment("apps", "apps/#/home")
                : new Uri(redirectUrl);
        }

        async Task<HttpResponseMessage> TwoFactorAuthentiationRedirectResponse(User user, string twoFacorMode, Uri redirectTo)
        {
            await _authVerify.UserCredentialsValidated(user, twoFacorMode);
            var userHasAppConfigured = !string.IsNullOrWhiteSpace(await _userTwoFactorAuthPreference.ResolveAppSecretKey(user.Id));
            var configuredModes = new List<string> { TwoFactorAuthVerify.Email };
            if (userHasAppConfigured)
            {
                var primaryMode = await _userTwoFactorAuthPreference.ResolvePreferredMethod(user.Id);
                if (primaryMode == TwoFactorAuthVerify.Email)
                {
                    configuredModes.Add(TwoFactorAuthVerify.App);
                }
                else
                {
                    configuredModes.Insert(0, TwoFactorAuthVerify.App);
                }
            }

            return Request.CreateResponse(HttpStatusCode.OK, new SignInResponse
            {
                Status = "codeRequired",
                ReturnUrl = redirectTo.ToString(),
                RequiresTwoFactorAuthentication = true,
                ConfiguredTwoFactorAuthModes = configuredModes.ToArray()
            });
        }

        HttpResponseMessage Redirect(string loginUrl, Uri redirectUri)
        {
            var response = Request.CreateResponse(HttpStatusCode.Moved);
            response.Headers.Location = new Uri($"{loginUrl}&redirect_uri={HttpUtility.UrlEncode(redirectUri.ToString())}");
            return response;
        }

        async Task<HttpResponseMessage> ValidateLicenseAndReturnSso(User user, string authMode, UserIdentityAccessData identityAccessData, string redirectUrl)
        {
            var validation = _userValidation.HasConfiguredAccess(user);
            if (!validation.Accepted)
            {
                var returnUri = SetErrorCode(validation.FailReasonCode, redirectUrl);
                throw new SsoException($"Error {validation}", returnUri);
            }

            AuthorizationResponse authorization;
            if (!_licenseAuthorization.TryAuthorize(user, out authorization))
            {
                var returnUri = SetErrorCode(authorization.FailReasonCode, redirectUrl,
                                             new Dictionary<string, string>
                                             {
                                                 {"param", authorization.Parameter}
                                             });
                throw new SsoException($"Error {authorization}", returnUri);
            }

            var redirectTo = string.IsNullOrEmpty(redirectUrl)
                ? Request.RequestUri.ReplaceStartingFromSegment("apps", "apps/#/home")
                : new Uri(redirectUrl);
            var ssoRedirectUrl = Request.RequestUri.ReplaceStartingFromSegment("apps", $"apps/signin/redirect/#/?goto={HttpUtility.UrlEncode(redirectTo.ToString())}").ToString();
            return await SuccessRedirect(user, ssoRedirectUrl, false, authMode, identityAccessData, null);
        }

        Uri SetErrorCode(string errorCode, string returnUrl, Dictionary<string, string> errorParameters = null)
        {
            errorCode = Uri.EscapeDataString(errorCode);
            returnUrl = string.IsNullOrEmpty(returnUrl) ? string.Empty : $"&goto={HttpUtility.UrlEncode(returnUrl)}";
            var strError = string.Empty;
            if (errorParameters != null)
            {
                foreach (var errorParam in errorParameters)
                    strError += $"&{errorParam.Key}={Uri.EscapeDataString(errorParam.Value)}";
            }

            return Request.RequestUri.ReplaceStartingFromSegment("apps", $"apps/signin/#/?errorCode={errorCode}{strError}{returnUrl}");
        }

        bool IsRequestFromSetupProgram(string redirectUrl)
        {
            return redirectUrl == "setup_test";
        }

        async Task ExpireCurrentUserSessionIfExists()
        {
            var currentData = Request.ParseAuthCookieDataWithExpiry(_authSettings);
            if (currentData.data != null)
            {
                await _userIdentityAccess.EndSessionIfOpen(currentData.data.LogId);
            }
        }
    }
}