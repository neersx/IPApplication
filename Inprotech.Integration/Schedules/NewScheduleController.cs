using System;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules.Extensions;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    public class NewScheduleController : ApiController
    {
        readonly IDataSourceSchedule _dataSourceSchedule;
        readonly IRepository _repository;

        public NewScheduleController(
            IRepository repository,
            IDataSourceSchedule dataSourceSchedule)
        {
            _repository = repository;
            _dataSourceSchedule = dataSourceSchedule;
        }

        [HttpPost]
        [Route("api/ptoaccess/newschedule/create")]
        public async Task<dynamic> Create(JObject scheduleRequest)
        {
            if (scheduleRequest == null) throw new ArgumentNullException(nameof(scheduleRequest));

            var result = await _dataSourceSchedule.TryCreateFrom(scheduleRequest);
            if (!result.IsValid)
            {
                return new
                {
                    Result = result.ValidationResult
                };
            }

            _repository.Set<Schedule>().Add(result.Schedule);
            _repository.SaveChanges();
            
            return new
            {
                Result = "success",
                result.Schedule.Id
            };
        }
    }
}