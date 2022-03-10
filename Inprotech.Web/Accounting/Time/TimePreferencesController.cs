using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Profiles;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Accounting.Time
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessToAllOf(ApplicationTask.MaintainTimeViaTimeRecording)]
    [RoutePrefix("api/accounting/time")]
    public class TimePreferencesController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IUserPreferenceManager _userPreferences;
        static readonly int[] TimeRecordingSettings =
        {
            KnownSettingIds.DisplayTimeWithSeconds,
            KnownSettingIds.AddEntryOnSave,
            KnownSettingIds.TimeFormat12Hours,
            KnownSettingIds.HideContinuedEntries,
            KnownSettingIds.ContinueFromCurrentTime,
            KnownSettingIds.ValueTimeOnEntry,
            KnownSettingIds.TimePickerInterval,
            KnownSettingIds.DurationPickerInterval
        };
        readonly IJsonPreferenceManager _preferenceManager;

        public TimePreferencesController(ISecurityContext securityContext,IUserPreferenceManager userPreferences, IJsonPreferenceManager preferenceManager)
        {
            _securityContext = securityContext;
            _userPreferences = userPreferences;
            _preferenceManager = preferenceManager;
        }

        [HttpGet]
        [Route("settings")]
        public async Task<UserPreference[]> ViewData()
        {
            return await GetUserPreferences();
        }

        [HttpPost]
        [Route("settings/update")]
        [RequiresAccessToAllOf(ApplicationTask.MaintainMyPreferences, ApplicationTaskAccessLevel.Modify)]
        public async Task<UserPreference[]> UpdateSettings(UserPreference[] settings)
        {
            var userId = _securityContext.User.Id;
            foreach (var userPreference in settings)
            {
                switch (userPreference.DataType)
                {
                    case "B":
                        _userPreferences.SetPreference(userId, userPreference.Id, userPreference.BooleanValue.GetValueOrDefault());
                        break;
                    case "I":
                        _userPreferences.SetPreference(userId, userPreference.Id, userPreference.IntegerValue.GetValueOrDefault());
                        break;
                }
            }

            return await GetUserPreferences();
        }

        [HttpPost]
        [Route("settings/reset")]
        [RequiresAccessToAllOf(ApplicationTask.MaintainMyPreferences, ApplicationTaskAccessLevel.Modify)]
        public async Task<UserPreference[]> ResetSettings()
        {
            _userPreferences.ResetUserPreferences(_securityContext.User.Id, TimeRecordingSettings);
            return await GetUserPreferences();
        }

        async Task<UserPreference[]> GetUserPreferences()
        {
            return await _userPreferences.GetPreferences<UserPreference>(_securityContext.User.Id, TimeRecordingSettings);
        }

        [HttpGet]
        [Route("settings/working-hours")]
        public WorkingHours GetWorkingHours()
        {
            var json = _preferenceManager.Get(_securityContext.User.Id, KnownSettingIds.WorkingHours);
            return json.ToObject<WorkingHours>();
        }

        [HttpPost]
        [Route("settings/update/working-hours")]
        public void UpdateSettingWorkingHours(WorkingHours workingHours)
        {
            _preferenceManager.Set(_securityContext.User.Id, KnownSettingIds.WorkingHours, JObject.FromObject(workingHours));
        }
    }

    public class WorkingHours
    {
        public int FromSeconds { get; set; }
        public int ToSeconds { get; set; }
    }
}
