using System;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    public class ScheduleFailuresController : ApiController
    {
        readonly IRepository _repository;

        public ScheduleFailuresController(IRepository repository)
        {
            if (repository == null) throw new ArgumentNullException(nameof(repository));
            _repository = repository;
        }

        [HttpGet]
        [Route("api/ptoaccess/scheduleExecutions/{id}/failures")]
        public dynamic Get(int id)
        {
            var failure = _repository.Set<ScheduleFailure>().FirstOrDefault(_ => _.ScheduleExecutionId == id);

            if (failure == null)
                return null;

            return new
            {
                failure.Date,
                Log = JsonConvert.DeserializeObject<dynamic>(failure.Log)
            };
        }
    }
}
