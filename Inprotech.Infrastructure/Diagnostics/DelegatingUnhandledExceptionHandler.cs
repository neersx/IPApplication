using System.Runtime.ExceptionServices;
using System.Web.Http.ExceptionHandling;

namespace Inprotech.Infrastructure.Diagnostics
{
    /// <summary>
    /// This exception handler delegates the responsibility to GlobalExceptionHandlerMiddleware
    /// for handling the exceptions. It doesnot throw context.Exception as it is, as this would
    /// re-write the stack trace and discard important information about what went wrong.
    /// </summary>
    public class DelegatingUnhandledExceptionHandler : ExceptionHandler
    {
        public override void Handle(ExceptionHandlerContext context)
        {
            var info = ExceptionDispatchInfo.Capture(context.Exception);
            info.Throw();
        }

        public override bool ShouldHandle(ExceptionHandlerContext context)
        {
            return true;
        }
    }
}