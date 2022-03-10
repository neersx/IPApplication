using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Processing
{
    public interface IAsyncCommandScheduler
    {
        Task ScheduleAsync(string command, Dictionary<string, object> parameters = null);
    }
}