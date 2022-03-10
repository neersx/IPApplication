using System.Threading.Tasks;

namespace Inprotech.Infrastructure
{
    public interface IMonitorClockRunnable
    {
        void Run();
    }

    public interface IMonitorClockRunnableAsync : IMonitorClockRunnable
    {
        Task RunAsync();
    }
}
