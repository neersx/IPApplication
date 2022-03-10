using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Recovery
{
    public class ReadScheduleSettings : IReadScheduleSettings
    {
        public const string ProcessId = "ProcessId";
        readonly IRepository _repository;

        public ReadScheduleSettings(IRepository repository)
        {
            _repository = repository;
        }

        public long GetTempStorageId(int scheduleId)
        {
            var schedule = _repository.Set<Schedule>().Single(s => s.Id == scheduleId);
            var extendedSettings = JObject.Parse(schedule.ExtendedSettings ?? "{}");
            return (long)extendedSettings["TempStorageId"];
        }

        public async Task<long> GetProcessId(int scheduleId) => (long)(await GetExtendedSettings(scheduleId))[ProcessId];

        public long GetProcessId(Schedule schedule) => (long)GetExtendedSettings(schedule.ExtendedSettings)[ProcessId];

        public JObject AddProcessId(string extendedSettings, long processId)
        {
            var settings = GetExtendedSettings(extendedSettings);
            settings[ProcessId] = processId;
            return settings;
        }

        async Task<JObject> GetExtendedSettings(int scheduleId)
        {
            var schedule = await _repository.Set<Schedule>().SingleAsync(s => s.Id == scheduleId);
            return GetExtendedSettings(schedule.ExtendedSettings);
        }

        JObject GetExtendedSettings(string extendedSettings)
        {
            var extendedSettingsObj = string.IsNullOrEmpty(extendedSettings)
                ? null
                : JObject.Parse(extendedSettings);
            extendedSettingsObj = extendedSettingsObj ?? new JObject();
            return extendedSettingsObj;
        }
    }
}