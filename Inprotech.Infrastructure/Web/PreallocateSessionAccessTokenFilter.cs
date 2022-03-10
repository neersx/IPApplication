using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure.Security.ExternalApplications;

namespace Inprotech.Infrastructure.Web
{
    public class PreallocateSessionAccessTokenFilter : IAutofacActionFilter
    {
        readonly ISessionAccessTokenGenerator _sessionAccessTokenGenerator;

        public PreallocateSessionAccessTokenFilter(ISessionAccessTokenGenerator sessionAccessTokenGenerator)
        {
            _sessionAccessTokenGenerator = sessionAccessTokenGenerator;
        }

        public Task OnActionExecutedAsync(HttpActionExecutedContext actionExecutedContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public async Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (actionContext.ActionDescriptor.GetCustomAttributes<PreallocateSessionAccessTokenAttribute>().Any() ||
                actionContext.ActionDescriptor.ControllerDescriptor.GetCustomAttributes<PreallocateSessionAccessTokenAttribute>().Any())
            {
                await _sessionAccessTokenGenerator.GetOrCreateAccessToken();
            }
        }
    }

    public interface ISessionAccessTokenGenerator
    {
        Task<Guid> GetOrCreateAccessToken(string applicationName = nameof(ExternalApplicationName.InprotechServer));
    }
}