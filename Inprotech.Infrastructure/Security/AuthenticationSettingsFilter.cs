using System;
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using Autofac.Integration.WebApi;

namespace Inprotech.Infrastructure.Security
{
    public class AuthenticationSettingsFilter : IAutofacAuthorizationFilter
    {
        readonly IAuthSettings _settings;

        public AuthenticationSettingsFilter(IAuthSettings settings)
        {
            _settings = settings;
        }

        public Task OnAuthorizationAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (actionContext == null) throw new ArgumentNullException(nameof(actionContext));

            var action = actionContext.ActionDescriptor;
            var controller = actionContext.ControllerContext.ControllerDescriptor;

            if (!action.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Any()
                && !controller.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Any())
            {
                return Task.FromResult(0);
            }

            if (!action.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>()
                       .Union(controller.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>())
                       .All(authMode => _settings.AuthenticationModeEnabled(authMode.AuthModeKey)))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            return Task.FromResult(0);
        }
    }
}