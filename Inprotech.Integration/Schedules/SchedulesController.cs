using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    public class SchedulesController : ApiController
    {
        readonly IAvailableDataSources _availableDataSources;
        readonly IIntegrationServerClient _integrationServerClient;
        readonly IRepository _repository;
        readonly IScheduleDetails _scheduleDetails;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _systemClock;

        public SchedulesController(
            IRepository repository,
            ISecurityContext securityContext,
            IAvailableDataSources availableDataSources,
            IIntegrationServerClient integrationServerClient,
            IScheduleDetails scheduleDetails,
            Func<DateTime> systemClock)
        {
            _repository = repository;
            _securityContext = securityContext;
            _availableDataSources = availableDataSources;
            _systemClock = systemClock;
            _integrationServerClient = integrationServerClient;
            _scheduleDetails = scheduleDetails;
        }

        [HttpDelete]
        [Route("api/ptoaccess/schedules/{id}")]
        public dynamic Delete(int id)
        {
            var schedule = _repository.Set<Schedule>().FirstOrDefault(s => s.Id == id);
            if (schedule == null || schedule.IsDeleted)
            {
                throw new ArgumentException("Unable to delete a non-existent schedule.");
            }

            if (!_availableDataSources.List().Contains(schedule.DataSourceType))
            {
                throw new Exception("Unable to delete a schedule with data source you do not have access to.");
            }

            SoftDeleteSchedule(schedule);

            var childSchedules = _repository.Set<Schedule>().Where(s => s.Parent != null && s.Parent.Id == id).ToArray();

            foreach (var c in childSchedules)
                SoftDeleteSchedule(c);

            _repository.SaveChanges();

            return new {Result = "success"};
        }

        void SoftDeleteSchedule(Schedule s)
        {
            s.IsDeleted = true;
            s.DeletedBy = _securityContext.User.Id;
            s.DeletedOn = _systemClock();
        }

        [HttpPost]
        [Route("api/ptoaccess/schedules/runnow/{id}")]
        public dynamic RunNow(int id)
        {
            var schedule = _repository.Set<Schedule>().FirstOrDefault(s => s.Id == id);
            if (schedule == null || schedule.IsDeleted)
            {
                throw new ArgumentException("Unable to run a non-existent schedule.");
            }

            if (!_availableDataSources.List().Contains(schedule.DataSourceType))
            {
                throw new Exception("Unable to run a Schedule for a Data Source Type you don't have access to.");
            }

            var runNowSchedule = CreateRunNowSchedule(schedule);
            _repository.Set<Schedule>().Add(runNowSchedule);
            _repository.SaveChanges();

            return new {Result = "success"};
        }
        
        [HttpPost]
        [Route("api/ptoaccess/schedules/stop/{id}")]
        public async Task<dynamic> Stop(int id)
        {
            using (var r = await _integrationServerClient.GetResponse($"api/schedules/stop/{id}/{_securityContext.User.Id}"))
            {
                r.EnsureSuccessStatusCode();
            }

            var schedules = _scheduleDetails.Get();

            return new
            {
                Result = "success",
                Schedules = schedules
            };
        }
        
        [HttpPost]
        [Route("api/ptoaccess/schedules/pause/{id}")]
        public async Task<dynamic> Pause(int id)
        {
            SetContinuousScheduleStatus(id, ScheduleState.Paused);

            var schedules = _scheduleDetails.Get();

            return new
            {
                Result = "success",
                Schedules = schedules
            };
        }

        [HttpPost]
        [Route("api/ptoaccess/schedules/resume/{id}")]
        public async Task<dynamic> Resume(int id)
        {
            SetContinuousScheduleStatus(id, ScheduleState.Active);
            var schedules = _scheduleDetails.Get();

            return new
            {
                Result = "success",
                Schedules = schedules
            };
        }

        void SetContinuousScheduleStatus(int id, ScheduleState state)
        {
            var schedule = _repository.Set<Schedule>().FirstOrDefault(s => s.Id == id && s.Type == ScheduleType.Continuous);
            if (schedule == null || schedule.IsDeleted)
            {
                throw new ArgumentException("Unable to resume a non-existent schedule.");
            }

            schedule.State = state;
            _repository.SaveChanges();
        }

        Schedule CreateRunNowSchedule(Schedule s)
        {
            var now = _systemClock();
            return new Schedule
                   {
                       Name = s.Name,
                       DownloadType = s.DownloadType,
                       CreatedOn = now,
                       CreatedBy = _securityContext.User.Id,
                       IsDeleted = false,
                       NextRun = now,
                       DataSourceType = s.DataSourceType,
                       ExtendedSettings = s.ExtendedSettings,
                       ExpiresAfter = now,
                       Parent = s,
                       State = ScheduleState.RunNow,
                       Type = ScheduleType.OnDemand
                   };
        }
    }
}