using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;

namespace Inprotech.Infrastructure.Caching
{
    /// <summary>
    ///     This fliter is used to set no-cache headers in response payload for get method in ApiController.
    ///     It is not required if deployed in IIS since no-cache header is set by default.
    /// </summary>
    public class NoCacheFilter : IAutofacActionFilter
    {
        public Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public Task OnActionExecutedAsync(HttpActionExecutedContext actionExecutedContext, CancellationToken cancellationToken)
        {
            if (actionExecutedContext.Response != null && actionExecutedContext.Request.Method == HttpMethod.Get)
            {
                var response = actionExecutedContext.Response;
                response.Headers.CacheControl = new CacheControlHeaderValue
                                                {
                                                    NoCache = true,
                                                    NoStore = true,
                                                    MaxAge = TimeSpan.Zero
                                                };

                if (response.Content != null)
                {
                    response.Content.Headers.Expires = DateTimeOffset.MinValue;
                }

                response.Headers.Pragma.Add(new NameValueHeaderValue("no-cache"));
            }

            return Task.FromResult(0);
        }
    }
}