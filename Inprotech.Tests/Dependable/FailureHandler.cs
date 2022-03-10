using System.Threading.Tasks;

#pragma warning disable 1998

namespace Inprotech.Tests.Dependable
{
    public class FailureHandler
    {
        protected SimpleLogger SimpleLogger;

        public FailureHandler(SimpleLogger simpleLogger)
        {
            SimpleLogger = simpleLogger;
        }

        public async Task Handle(int sequence)
        {
            SimpleLogger.Write(this, "Handle the failure for " + sequence + ".");
        }

        public async Task HandleAny()
        {
            SimpleLogger.Write(this, "Handle the failure.");
        }
    }
}