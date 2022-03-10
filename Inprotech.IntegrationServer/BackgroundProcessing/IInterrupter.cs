using System.Threading.Tasks;

namespace Inprotech.IntegrationServer.BackgroundProcessing
{
    public interface IInterrupter
    {
        Task Interrupt();
    }
}