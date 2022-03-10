using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Security;
using InprotechKaizen.Model.Components.Security;
using Microsoft.Owin;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Server.Security
{
    public class WindowsAuthenticationMiddleware : OwinMiddleware
    {
        readonly IAuthSettings _authSettings;
        readonly ILicenseAuthorization _licenseAuthorization;
        readonly IUserAuditLogger<WindowsAuthenticationMiddleware> _logger;
        readonly IPrincipalUser _principalUser;
        readonly ITokenExtender _tokenExtender;
        readonly ISourceIpAddressResolver _sourceIpAddressResolver;
        readonly IUserIdentityAccessManager _userIdentityAccess;
        readonly IUserValidation _userValidation;

        public WindowsAuthenticationMiddleware(OwinMiddleware next, IPrincipalUser principalUser, IAuthSettings authSettings, ILicenseAuthorization licenseAuthorization, IUserValidation userValidation,
                                               IUserAuditLogger<WindowsAuthenticationMiddleware> logger, 
                                               IUserIdentityAccessManager userIdentityAccess, 
                                               ITokenExtender tokenExtender,
                                               ISourceIpAddressResolver sourceIpAddressResolver) : base(next)
        {
            _principalUser = principalUser;
            _authSettings = authSettings;
            _licenseAuthorization = licenseAuthorization;
            _userValidation = userValidation;
            _logger = logger;
            _userIdentityAccess = userIdentityAccess;
            _tokenExtender = tokenExtender;
            _sourceIpAddressResolver = sourceIpAddressResolver;
        }

        public override async Task Invoke(IOwinContext context)
        {
            context.Response.ContentType = "application/json";

            var (status, response) = await TrySignInWithWindows(context);
            if (!status)
            {
                _logger.Warning((response as WinAuthResponse)?.UserName + " | Sign-in with windows failed  with status " + (response as WinAuthResponse)?.Status, context.Request);
            }

            var serialised = JsonConvert.SerializeObject(response,
                                                         Formatting.Indented,
                                                         new JsonSerializerSettings
                                                         {
                                                             ContractResolver = new CamelCasePropertyNamesContractResolver()
                                                         });

            await context.Response.WriteAsync(serialised);
        }

        async Task<(bool status, object response)> TrySignInWithWindows(IOwinContext context)
        {
            if (!context.Authentication.User.Identity.IsAuthenticated)
            {
                return (false, new WinAuthResponse {Status = "unauthorised-windows-user"});
            }

            var user = _principalUser.From(context.Authentication.User);
            if (user == null)
            {
                return (false, new WinAuthResponse {Status = "unauthorised-windows-user"});
            }

            if (!string.IsNullOrWhiteSpace(context.Request.Query["extend"]))
            {
                var cookieData = context.Request.ParseAuthCookie(_authSettings);
                (var shouldExtend, var tokenValid) = await _tokenExtender.ShouldExtend(cookieData);
                if (shouldExtend)
                {
                    context.Response.WithAuthCookie(_authSettings, new AuthUser(user.UserName, user.Id, AuthenticationModeKeys.Windows, cookieData.LogId));
                }

                if (tokenValid)
                {
                    return (true, new WinAuthResponse
                    {
                        Status = "success",
                        UserName = user.UserName
                    });
                }
            }

            var r = _userValidation.HasConfiguredAccess(user);
            if (!r.Accepted)
            {
                return (false, r);
            }

            if (user.IsLocked)
            {
                return (false, new AuthorizationResponse("unauthorised-accounts-locked"));
            }

            if (!_licenseAuthorization.TryAuthorize(user, out var authorization))
            {
                return (false, authorization);
            }

            var source = _sourceIpAddressResolver.Resolve(context);

            var logId = _userIdentityAccess.StartSession(user.Id, AuthenticationModeKeys.Windows, null, context.Request.Query["application"], source);
            await ExpireCurrentUserSessionIfExists(context);

            context.Response.WithAuthCookie(_authSettings, new AuthUser(user.UserName, user.Id, AuthenticationModeKeys.Windows, logId));

            var redirectUrl = context.Request.Query["redirectUrl"];
            var redirectTo = string.IsNullOrWhiteSpace(redirectUrl)
                ? context.Request.Uri.ReplaceStartingFromSegment("winAuth", "apps/#/home")
                : new Uri(redirectUrl);

            return (true,
                new WinAuthResponse
                {
                    Status = "success",
                    UserName = user.UserName,
                    ReturnUrl = redirectTo
                });
        }

        async Task ExpireCurrentUserSessionIfExists(IOwinContext context)
        {
            var currentData = context.Request.ParseAuthCookieDataWithExpiry(_authSettings);
            if (currentData.data != null)
            {
                await _userIdentityAccess.EndSessionIfOpen(currentData.data.LogId);
            }
        }
    }

    public class WinAuthResponse
    {
        public string Status { get; set; }

        public string UserName { get; set; }

        public Uri ReturnUrl { get; set; }
    }
}