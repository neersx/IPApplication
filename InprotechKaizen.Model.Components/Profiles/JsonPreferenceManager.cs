using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json.Linq;

namespace InprotechKaizen.Model.Components.Profiles
{
    public class JsonPreferenceManager : IJsonPreferenceManager
    {
        readonly IUserPreferenceManager _preferenceManager;
        readonly int[] _typeJson = {KnownSettingIds.AppsHomePage, KnownSettingIds.WorkingHours};

        public JsonPreferenceManager(IUserPreferenceManager preferenceManager)
        {
            _preferenceManager = preferenceManager;
        }

        public JObject Get(int userId, int settingId)
        {
            if (!_typeJson.Contains(settingId)) throw new ArgumentException();

            return JObject.Parse(_preferenceManager.GetPreference<string>(userId, settingId));
        }

        public void Set(int userId, int settingId, JObject value)
        {
            if (!_typeJson.Contains(settingId)) throw new ArgumentException();

            _preferenceManager.SetPreference(userId, settingId, value.ToString());
        }

        public void Reset(int userId, int settingId)
        {
            if (!_typeJson.Contains(settingId)) throw new ArgumentException();

            _preferenceManager.ResetUserPreferences(userId, new[] {settingId});
        }
    }
}