using System.Threading.Tasks;
using Autofac.Features.AttributeFilters;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Schedules.Extensions.FileApp
{
    public class CreateSchedule : ICreateSchedule
    {
        readonly IDataSourceSchedulePrerequisites _prerequisites;

        public CreateSchedule([KeyFilter(DataSourceType.File)] IDataSourceSchedulePrerequisites prerequisites)
        {
            _prerequisites = prerequisites;
        }

        public Task<DataSourceScheduleResult> TryCreateFrom(JObject scheduleRequest)
        {
            var fileAppSchedule = scheduleRequest.ToObject<FileAppSchedule>();
            var result = ValidateScheduleRequest(fileAppSchedule) ?? new DataSourceScheduleResult
            {
                ValidationResult = "success",
                Schedule = new Schedule
                {
                    ExtendedSettings = JsonConvert.SerializeObject(fileAppSchedule)
                }
            };

            return Task.FromResult(result);
        }
        DataSourceScheduleResult ValidateScheduleRequest(FileAppSchedule schedule)
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
