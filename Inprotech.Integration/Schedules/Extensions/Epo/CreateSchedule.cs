using System.Threading.Tasks;
using Autofac.Features.AttributeFilters;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Schedules.Extensions.Epo
{
    public class CreateSchedule : ICreateSchedule
    {
        readonly IDataSourceSchedulePrerequisites _prerequisites;

        public CreateSchedule([KeyFilter(DataSourceType.Epo)] IDataSourceSchedulePrerequisites prerequisites)
        {
            _prerequisites = prerequisites;
        }

        public Task<DataSourceScheduleResult> TryCreateFrom(JObject scheduleRequest)
        {
            var epoSchedule = scheduleRequest.ToObject<EpoSchedule>();
            var result = ValidateScheduleRequest(epoSchedule) ?? new DataSourceScheduleResult
            {
                ValidationResult = "success",
                Schedule = new Schedule
                {
                    ExtendedSettings = JsonConvert.SerializeObject(epoSchedule)
                }
            };

            return Task.FromResult(result);
        }

        public Task ScheduleCreated(Schedule schedule)
        {
            return Task.FromResult((object) null);
        }

        DataSourceScheduleResult ValidateScheduleRequest(EpoSchedule schedule)
        {
            if (!_prerequisites.Validate(out string unmetRequirement))
            {
                return new DataSourceScheduleResult { ValidationResult = unmetRequirement };
            }

            if (!schedule.SavedQueryId.HasValue)
                return new DataSourceScheduleResult { ValidationResult = "invalid-saved-query" };

            if (!schedule.RunAsUserId.HasValue)
                return new DataSourceScheduleResult { ValidationResult = "invalid-run-as-user" };

            return null;
        }
    }
}
