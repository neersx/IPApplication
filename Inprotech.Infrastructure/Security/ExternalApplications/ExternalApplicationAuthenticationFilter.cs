using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;

namespace Inprotech.Infrastructure.Security.ExternalApplications
{
    public class ExternalApplicationAuthenticationFilter : IAutofacAuthenticationFilter
    {
        const string HeaderApiKey = "X-ApiKey";
        const string HeaderUserName = "X-UserName";
        readonly IApiKeyValidator _apiKeyValidator;
        readonly IExternalApplicationContext _externalApplicationContext;
        readonly IUserValidator _userValidator;

        public ExternalApplicationAuthenticationFilter(IApiKeyValidator apiKeyValidator, IUserValidator userValidator, IExternalApplicationContext externalApplicationContext)
        {
            _apiKeyValidator = apiKeyValidator;
            _externalApplicationContext = externalApplicationContext;
            _userValidator = userValidator;
        }

        public async Task AuthenticateAsync(HttpAuthenticationContext authenticationContext, CancellationToken cancellationToken)
        {
            var requiresApiKey = authenticationContext.ActionContext.ControllerContext.ControllerDescriptor.GetCustomAttributes<RequiresApiKeyAttribute>().SingleOrDefault();

            if (requiresApiKey == null) return;

            var applicationName = requiresApiKey.ExternalApplicationName.ToString();
            string username = null;

            if (authenticationContext.Request.Headers.TryGetValues(HeaderUserName, out var headerValues))
            {
                username = headerValues.First();
                if (!await _userValidator.ValidateUser(username))
                {
                    HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.InvalidUser.ToString());
                }
            }
            else if (requiresApiKey.UserRequired)
            {
                HttpResponseExceptionHelper.RaiseBadRequest(ErrorTypeCode.UsernameNotProvided.ToString());
            }

            if (authenticationContext.Request.Headers.TryGetValues(HeaderApiKey, out headerValues))
            {
                var apiKey = headerValues.First();

                if (!await _apiKeyValidator.ValidateApiToken(apiKey, applicationName, requiresApiKey.IsOneTimeUse))
                {
                    HttpResponseExceptionHelper.RaiseUnauthorized(ErrorTypeCode.InvalidApikey.ToString());
                }
            }
            else
            {
                HttpResponseExceptionHelper.RaiseBadRequest(ErrorTypeCode.ApikeyNotProvided.ToString());
            }

            authenticationContext.Principal = new ExternalApplicationPrincipal(username);

            _externalApplicationContext.SetApplicationName(applicationName);
        }

        public Task ChallengeAsync(HttpAuthenticationChallengeContext context, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }
    }
}