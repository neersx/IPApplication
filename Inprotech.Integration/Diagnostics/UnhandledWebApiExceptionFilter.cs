using System;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ExceptionHandling;
using System.Web.Http.Filters;
using System.Web.Http.Results;
using Autofac.Integration.WebApi;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;
using NLog;

namespace Inprotech.Integration.Diagnostics
{
    /// <summary>
    /// Logs unhandled exceptions in ApiControllers.    
    /// </summary>
    public class UnhandledWebApiExceptionFilter : IAutofacExceptionFilter
    {
        readonly ILogger<UnhandledWebApiExceptionFilter> _logger;
       
        public UnhandledWebApiExceptionFilter(
            ILogger<UnhandledWebApiExceptionFilter> logger)
        {
            if (logger == null) throw new ArgumentNullException(nameof(logger));
            
            _logger = logger;
        }

        public Task OnExceptionAsync(HttpActionExecutedContext context, CancellationToken cancellationToken)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));

            if (context.Exception is DataSecurityException)
            {
                return Task.CompletedTask;
            }

            _logger.Exception(context.Exception);

            var httpException = context.Exception as HttpResponseException;
            
            if (httpException == null)
            {
                context.Response = context.Request.CreateResponse(
                                                                  HttpStatusCode.InternalServerError,
                                                                  ErrorTypeCode.ServerError.ToString().CamelCaseToUnderscore());
            }
            else
            {
                context.Response = httpException.Response;
            }

            return Task.CompletedTask;
        }
    }

    public class UnhandledWebApiExceptionHandler : ExceptionHandler
    {
        public override Task HandleAsync(ExceptionHandlerContext context, CancellationToken cancellationToken)
        {
            var dependencyScope = context.Request.GetDependencyScope();

            var logger = (ILogger<UnhandledWebApiExceptionHandler>) dependencyScope.GetService(typeof(ILogger<UnhandledWebApiExceptionHandler>));

            logger.Exception(context.Exception);

            var httpException = context.Exception as HttpResponseException;
            
            if (httpException == null)
            {
                context.Result = new ResponseMessageResult(context.Request
                                                                  .CreateResponse(
                                                                                          HttpStatusCode.InternalServerError,
                                                                                          ErrorTypeCode.ServerError.ToString().CamelCaseToUnderscore()));

            }
            else
            {
                context.Result = new ResponseMessageResult(httpException.Response);
            }

            return Task.CompletedTask;
        }
    }
}