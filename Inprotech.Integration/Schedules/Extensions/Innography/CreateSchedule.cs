using System.Threading.Tasks;
using Autofac.Features.AttributeFilters;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Schedules.Extensions.Innography
{
    internal class CreateSchedule : ICreateSchedule
    {
        readonly IDataSourceSchedulePrerequisites _prerequisites;

        public CreateSchedule([KeyFilter(DataSourceType.IpOneData)] IDataSourceSchedulePrerequisites prerequisites)
        {
            _prerequisites = prerequisites;
        }

        public Task<DataSourceScheduleResult> TryCreateFrom(JObject scheduleRequest)
        {
            var innographySchedule = scheduleRequest.ToObject<InnographySchedule>();
            var result = ValidateScheduleRequest(innographySchedule) ?? new DataSourceScheduleResult
            {
                ValidationResult = "success",
                Schedule = new Schedule
                {
                    ExtendedSettings = JsonConvert.SerializeObject(innographySchedule)
                }
            };

            return Task.FromResult(result);
        }

        DataSourceScheduleResult ValidateScheduleRequest(InnographySchedule schedule)
        {
            string unmetRequirement;
            if (!_prerequisites.Validate(out unmetRequirement))
            {
                return new DataSourceScheduleResult {ValidationResult = unmetRequirement};
            }

            if (!schedule.SavedQueryId.HasValue)
            {
                return new DataSourceScheduleResult {ValidationResult = "invalid-saved-query"};
            }

            if (!schedule.RunAsUserId.HasValue)
            {
                return new DataSourceScheduleResult {ValidationResult = "invalid-run-as-user"};
            }

            return null;
        }
    }
}