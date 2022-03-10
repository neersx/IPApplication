using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure;

namespace Inprotech.Integration.Filters
{
    public class HandleNullArgumentFilter : IAutofacActionFilter
    {
        public Task OnActionExecutedAsync(HttpActionExecutedContext actionExecutedContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (!actionContext.ActionDescriptor.GetCustomAttributes<HandleNullArgumentAttribute>().Any())
            {
                return Task.FromResult(0);
            }

            if (actionContext.ActionArguments.ContainsValue(null))
            {
                actionContext.Response = actionContext.Request.CreateErrorResponse(HttpStatusCode.BadRequest,
                                                                                   ErrorTypeCode.InvalidParameter.ToString());
            }

            return Task.FromResult(0);
        }
    }
}