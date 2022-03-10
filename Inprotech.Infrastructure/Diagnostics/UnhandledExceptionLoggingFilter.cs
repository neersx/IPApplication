using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Exceptions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.Diagnostics
{
    public class UnhandledExceptionLoggingFilter : IAutofacExceptionFilter
    {
        readonly ICurrentUser _currentUser;
        readonly ILogger<UnhandledExceptionLoggingFilter> _logger;
        readonly IRequestContext _requestContext;

        public UnhandledExceptionLoggingFilter(
            ILogger<UnhandledExceptionLoggingFilter> logger,
            IRequestContext requestContext,
            ICurrentUser currentUser)
        {
            _logger = logger;
            _requestContext = requestContext;
            _currentUser = currentUser;
        }

        public Task OnExceptionAsync(HttpActionExecutedContext context, CancellationToken cancellationToken)
        {
            if (context.IsExceptionHandled()) return Task.FromResult((object) null);

            _logger.Exception(context.Exception);

            var httpException = context.Exception as HttpResponseException;

            // If exception being thrown is an HttpResponseException, we shouldn't modify it
            // because, we could potentially override the response intended by the ApiController.
            if (httpException == null)
            {
                context.Response = context.Request.CreateResponse(
                                                                  HttpStatusCode.InternalServerError,
                                                                  new
                                                                  {
                                                                      Status = "UnhandledException",
#if DEBUG
                                                                      Exception = context.Exception.ToString(),
#endif
                                                                      CorrelationId = _requestContext?.RequestId,
                                                                      User = _currentUser?.Identity?.Name
                                                                  });
            }
            else
            {
                context.Response = httpException.Response;
            }

            return Task.FromResult((object) null);
        }
    }
}