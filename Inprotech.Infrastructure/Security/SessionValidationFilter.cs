using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure.Hosting;

namespace Inprotech.Infrastructure.Security
{
    public class SessionValidationFilter : IAutofacAuthorizationFilter
    {
        readonly ISessionValidator _sessionValidator;
        readonly IAuthSettings _settings;

        public SessionValidationFilter(ISessionValidator sessionValidator, IAuthSettings settings)
        {
            _sessionValidator = sessionValidator;
            _settings = settings;
        }

        public Task OnAuthorizationAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            var ctx = actionContext.Request.GetOwinContext();
            if (ctx == null)
            {
                return Task.FromResult(0);
            }

            var requiresAuthorization = actionContext.ActionDescriptor
                                                     .GetCustomAttributes<AuthorizeAttribute>()
                                                     .Any() ||
                                        actionContext.ActionDescriptor
                                                     .ControllerDescriptor
                                                     .GetCustomAttributes<AuthorizeAttribute>()
                                                     .Any();

            if (!requiresAuthorization || !ctx.Environment.TryGetValue("LogId", out object logIdObj) || logIdObj == null)
            {
                return Task.FromResult(0);
            }

            var logId = (long) logIdObj;
            if (!_sessionValidator.IsSessionValid(logId))
            {
                actionContext.Response = actionContext.Request
                                                      .CreateResponse(HttpStatusCode.Unauthorized)
                                                      .WithExpiredCookie(_settings.SessionCookieName, _settings.SessionCookiePath, _settings.SessionCookieDomain);
            }

            return Task.FromResult(0);
        }
    }
}