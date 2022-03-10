using System;
using System.Web.Http.Filters;

namespace Inprotech.Infrastructure.Exceptions
{
    public static class HttpActionExecutedContextExceptionHandledExtension
    {
        public static void SetIsExceptionHandled(this HttpActionExecutedContext context, Type exceptionType)
        {
            context.Request.Properties["IsExceptionHandled"] = exceptionType.FullName;
        }

        public static bool IsExceptionHandled(this HttpActionExecutedContext context)
        {
            return context.Request.Properties.TryGetValue("IsExceptionHandled", out var exceptionType)
                   && (string) exceptionType == context.Exception.GetType().FullName;
        }
    }
}