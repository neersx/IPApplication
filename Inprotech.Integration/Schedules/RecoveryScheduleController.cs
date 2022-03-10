using System.Web.Http;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    public class RecoveryScheduleController : ApiController
    {
        readonly IRecoverableSchedule _recoverableSchedule;

        public RecoveryScheduleController(IRecoverableSchedule recoverableSchedule)
        {
            _recoverableSchedule = recoverableSchedule;
        }

        [HttpPost]
        [Route("api/ptoaccess/schedules/{scheduleId:int}/recovery")]
        public void Recover(int scheduleId)
        {
            _recoverableSchedule.Recover(scheduleId);
        }
    }
}