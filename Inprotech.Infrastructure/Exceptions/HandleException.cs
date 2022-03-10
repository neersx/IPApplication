using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Filters;

namespace Inprotech.Infrastructure.Exceptions
{
    public class HandleException : ExceptionFilterAttribute
    {
        const string Handler = "Handle";

        public HandleException(Type exceptionType, Type handlerType)
        {
            ExceptionType = exceptionType;
            HandlerType = handlerType;
        }

        public Type ExceptionType { get; set; }

        public Type HandlerType { get; set; }

        public string HandlerAction { get; set; } = Handler;

        public override void OnException(HttpActionExecutedContext actionExecutedContext)
        {
            Handle(actionExecutedContext);
        }

        public override async Task OnExceptionAsync(HttpActionExecutedContext actionExecutedContext, CancellationToken cancellationToken)
        {
            Handle(actionExecutedContext);
        }

        void Handle(HttpActionExecutedContext actionExecutedContext)
        {
            const BindingFlags flags = BindingFlags.InvokeMethod | BindingFlags.Static | BindingFlags.Public;
            var ex = actionExecutedContext.Exception;
            if (ex.GetType() != ExceptionType) return;
            if (HandlerType.InvokeMember(HandlerAction, flags, null, null, null) is HttpResponseMessage message)
            {
                actionExecutedContext.Response = message;
                actionExecutedContext.Response.Headers.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true,
                    NoStore = true,
                    MaxAge = TimeSpan.Zero
                };
                if (actionExecutedContext.Response.Content != null)
                {
                    actionExecutedContext.Response.Content.Headers.Expires = DateTimeOffset.MinValue;
                }

                actionExecutedContext.Response.Headers.Pragma.Add(new NameValueHeaderValue("no-cache"));
                actionExecutedContext.SetIsExceptionHandled(ex.GetType());
            }
        }
    }
}