using System;
using System.Threading.Tasks;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public interface IUpdateScheduleExecutionStatus
    {
        Task SetToTidiedUp(Guid sessionGuid);
    }
}