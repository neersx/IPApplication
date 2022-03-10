using System.Threading.Tasks;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Recovery
{
    public interface IReadScheduleSettings
    {
        long GetTempStorageId(int scheduleId);

        Task<long> GetProcessId(int scheduleId);

        long GetProcessId(Schedule schedule);

        JObject AddProcessId(string extendedSettings, long processId);
    }
}