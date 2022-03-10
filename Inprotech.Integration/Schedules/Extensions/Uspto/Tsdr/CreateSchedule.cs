using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Schedules.Extensions.Uspto.Tsdr
{
    public class CreateSchedule : ICreateSchedule
    {
        public Task<DataSourceScheduleResult> TryCreateFrom(JObject scheduleRequest)
        {
            var tsdrSchedule = scheduleRequest.ToObject<TsdrSchedule>();
            var result = ValidateScheduleRequest(tsdrSchedule) ?? new DataSourceScheduleResult
            {
                ValidationResult = "success",
                Schedule = new Schedule
                {
                    ExtendedSettings = JsonConvert.SerializeObject(tsdrSchedule)
                }
            };

            return Task.FromResult(result);
        }

        static DataSourceScheduleResult ValidateScheduleRequest(TsdrSchedule schedule)
        {
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