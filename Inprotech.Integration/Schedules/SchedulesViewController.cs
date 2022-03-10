using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    public class SchedulesViewController : ApiController
    {
        readonly IScheduleDetails _scheduleDetails;

        public SchedulesViewController(IScheduleDetails scheduleDetails)
        {
            _scheduleDetails = scheduleDetails;
        }

        [HttpGet]
        [Route("api/ptoaccess/schedulesview")]
        [NoEnrichment]
        public dynamic Get()
        {
            return new
            {
                Schedules = _scheduleDetails.Get()
            };
        }
    }
}