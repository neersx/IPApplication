using System.Linq;
using Dependable.Dispatcher;

namespace Inprotech.Tests.Dependable
{
    public class ExceptionFilter
    {
        protected SimpleLogger SimpleLogger;

        public ExceptionFilter(SimpleLogger simpleLogger)
        {
            SimpleLogger = simpleLogger;
        }

        public void LogIncomingException(ExceptionContext ex)
        {
            SimpleLogger.Write(this, "Log this exception: " + ex.Exception.Message + " for " + ex.Method + "(" + ex.Arguments.Single() + ")");
        }
    }
}