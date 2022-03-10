using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Exceptions;

namespace Inprotech.Infrastructure.Diagnostics
{
    public class DataSecurityExceptionLoggingFilter : IAutofacExceptionFilter
    {
        readonly ILogger<DataSecurityException> _logger;

        public DataSecurityExceptionLoggingFilter(
            ILogger<DataSecurityException> logger)
        {
            _logger = logger;
        }

        public Task OnExceptionAsync(HttpActionExecutedContext context, CancellationToken cancellationToken)
        {
            if (context.Exception is DataSecurityException)
            {
                _logger.Exception(context.Exception);
                context.SetIsExceptionHandled(typeof(DataSecurityException));
                context.Response = context.Request.CreateResponse(
                                                                  HttpStatusCode.NotFound);
            }

            return Task.FromResult((object)null);
        }
    }
}
