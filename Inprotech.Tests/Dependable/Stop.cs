using System.Threading.Tasks;

#pragma warning disable 1998

namespace Inprotech.Tests.Dependable
{
    public class Stop
    {
        protected SimpleLogger SimpleLogger;

        public Stop(SimpleLogger simpleLogger)
        {
            SimpleLogger = simpleLogger;
        }

        public async Task Cleanup()
        {
            SimpleLogger.Write(this, "Complete!");
        }
    }
}