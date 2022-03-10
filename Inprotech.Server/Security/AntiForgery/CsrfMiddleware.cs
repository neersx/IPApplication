using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.AntiForgery;
using Inprotech.Web.Security;
using Microsoft.Owin;

namespace Inprotech.Server.Security.AntiForgery
{
    /// <summary>
    /// This CSRF middleware implementation is an extension of Owin.AntiForgery middleware
    /// package. Original Author of Owin.AntiForgery is Onat Yiğit Mercan. The link to the
    /// source code is https://github.com/onatm/Owin.Antiforgery/tree/master/src
    /// </summary>
    public class CsrfMiddleware : OwinMiddleware
    {
        readonly IAuthSettings _authSettings;
        readonly ILogger<CsrfMiddleware> _logger;

        public CsrfMiddleware(OwinMiddleware next, IAuthSettings authSettings, ILogger<CsrfMiddleware> logger) : base(next)
        {
            _authSettings = authSettings;
            _logger = logger;
        }

        public override async Task Invoke(IOwinContext context)
        {
            var config = context.GetCsrfConfigOptions();
            if (!config.ShouldIssueCsrfToken)
            {
                await Invoke(Next, context);
                return;
            }

            var requestHeaders = context.Request.Headers;

            if (config.SafeMethods.Contains(context.Request.Method))
            {
                await Invoke(Next, context);
            }
            else if ((context.Request.Path.ToString().Contains(Urls.ApiSignIn) || context.Request.Path.ToString().Contains(Urls.ResetPassword)) && (context.Request.Method == HttpMethod.Post.ToString() || context.Request.Method == HttpMethod.Put.ToString()))
            {
                await Invoke(Next, context);
            }
            else
            {
                if (OptionsContainIgnoredUrls(context.Request, config))
                {
                    await Invoke(Next, context);
                    return;
                }
                
                if (!context.Request.Cookies.Any())
                {
                    _logger.Warning("Invalid Request. No cookies in the secured (https) request.", context.Request.Uri);
                    context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                    context.Response.ReasonPhrase = "No cookies in the secured (https) request.";
                    return;
                }

                if (string.IsNullOrWhiteSpace(context.Request.Cookies[_authSettings.SessionCookieName]))
                {
                    _logger.Warning("Invalid Request. Auth cookie not sent in the request.", context.Request.Uri);
                    context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                    context.Response.ReasonPhrase = "Auth cookie not sent in the request.";
                    return;
                }

                if (string.IsNullOrWhiteSpace(context.Request.Cookies[CsrfConfigOptions.CookieName]))
                {
                    _logger.Warning("Invalid Request. Csrf cookie not sent in the request.", context.Request.Uri);
                    context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                    context.Response.ReasonPhrase = "Csrf cookie not sent in the request.";
                    return;
                }

                if (!requestHeaders.ContainsKey(CsrfConfigOptions.HeaderName))
                {
                    _logger.Warning("Invalid Request. Csrf header not present in the request.", context.Request.Uri);
                    context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                    context.Response.ReasonPhrase = "Csrf header not present in the request.";
                    return;
                }

                var csrfCookieToken = context.Request.Cookies[CsrfConfigOptions.CookieName];

                var csrfToken = requestHeaders[CsrfConfigOptions.HeaderName];

                var isValid = AntiForgeryToken.Validate(csrfToken, csrfCookieToken);

                if (!isValid)
                {
                    _logger.Warning("Invalid Request. Csrf token in the header and auth cookie token doesnot match.", context.Request.Uri);
                    context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                    context.Response.ReasonPhrase = "Csrf token in the header and auth cookie token doesnot match.";
                    return;
                }

                await Invoke(Next, context);
            }
        }

        static bool OptionsContainIgnoredUrls(IOwinRequest request, CsrfConfigOptions config)
        {
            return config.IgnoreUrls.Any(ignoredUrl => request.Uri.ToString().ToLowerInvariant().Contains(ignoredUrl.ToLowerInvariant()));
        }

        static async Task Invoke(OwinMiddleware next, IOwinContext context)
        {
            if (next == null)
                return;

            await next.Invoke(context);
        }
    }
}
