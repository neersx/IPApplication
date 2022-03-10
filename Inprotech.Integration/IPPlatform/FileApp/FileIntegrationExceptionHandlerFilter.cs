using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public class FileIntegrationExceptionHandlerFilter : IAutofacExceptionFilter
    {
        public Task OnExceptionAsync(HttpActionExecutedContext context, CancellationToken cancellationToken)
        {
            var ctx = context.ActionContext;
            if (ctx?.ActionDescriptor == null || !ctx.ActionDescriptor.GetCustomAttributes<HandleFileIntegrationErrorAttribute>().Any())
            {
                return Task.FromResult(0);
            }

            var type = ctx.ActionDescriptor.GetCustomAttributes<HandleFileIntegrationErrorAttribute>().Single();
            var fileIntegrationException = context.Exception as FileIntegrationException;
            if (fileIntegrationException == null || !type.StatusCodes.Contains(fileIntegrationException.StatusCode))
            {
                return Task.FromResult(0);
            }

            // Logging is handled by UnhandledWebApiFilter.

            context.Response = new HttpResponseMessage(fileIntegrationException.StatusCode);

            return Task.FromResult(0);
        }
    }
}