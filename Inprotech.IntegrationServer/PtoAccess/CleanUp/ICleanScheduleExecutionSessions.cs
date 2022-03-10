using System;
using System.Threading.Tasks;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public interface ICleanScheduleExecutionSessions
    {
        Task Clean(Guid sessionGuid, string rootSessionPath);
    }
}