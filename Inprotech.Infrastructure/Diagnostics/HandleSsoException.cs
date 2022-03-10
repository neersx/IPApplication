using System;
using System.Diagnostics.CodeAnalysis;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Filters;
using Autofac;
using Autofac.Integration.WebApi;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure.Diagnostics
{
    public class HandleSsoException : ExceptionFilterAttribute
    {
        public override void OnException(HttpActionExecutedContext context)
        {
            var exception = context.Exception as SsoException;
            if (exception != null)
            {
                ILogger<HandleSsoException> logger;
                
                var scope = context.Request.GetDependencyScope()?.GetRequestLifetimeScope();
                if (scope != null && scope.TryResolve(out logger))
                {
                    logger.Exception(exception);
                }

                var msg = new HttpResponseMessage(HttpStatusCode.Redirect);
                msg.Headers.Location = exception.ReturnUrl;
                throw new HttpResponseException(msg);
            }
        }
    }

    [SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    public class SsoException : Exception
    {
        public SsoException(string message, Uri returnUrl) : base(message)
        {
            ReturnUrl = returnUrl;
        }

        public SsoException(string message, Exception innerException, Uri returnUrl) : base(message, innerException)
        {
            ReturnUrl = returnUrl;
        }

        public Uri ReturnUrl { get; set; }
    }
}