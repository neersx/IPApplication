using Inprotech.Integration.Persistence;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Linq;
using System.Threading.Tasks;

namespace Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair
{
    public class CreateSchedule : ICreateSchedule
    {
        readonly IRepository _repository;

        public CreateSchedule(IRepository repository)
        {
            _repository = repository;
        }

        public Task<DataSourceScheduleResult> TryCreateFrom(JObject scheduleRequest)
        {
            var privatePairSchedule = scheduleRequest.ToObject<PrivatePairSchedule>();
            var validationErrors = ValidateScheduleRequest();

            return Task.FromResult(validationErrors ?? new DataSourceScheduleResult
            {
                ValidationResult = "success",
                Schedule = new Schedule
                {
                    ExtendedSettings = JsonConvert.SerializeObject(privatePairSchedule)
                }
            });
        }

        DataSourceScheduleResult ValidateScheduleRequest()
        {
            return _repository.NoDeleteSet<Sponsorship>().Any(c => c.ServiceId != null && c.ServiceId.Trim() != string.Empty) ? null : new DataSourceScheduleResult { ValidationResult = "missing-uspto-sponsorship" };
        }
    }
}