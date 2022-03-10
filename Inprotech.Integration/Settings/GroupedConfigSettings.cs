using System;
using Inprotech.Contracts.Settings;

namespace Inprotech.Integration.Settings
{
    public class GroupedConfigSettings : IGroupedSettings
    {
        readonly string _group;
        readonly ISettings _settings;

        public delegate GroupedConfigSettings Factory(string group);

        [Obsolete("For testing purpose only")]
        public GroupedConfigSettings()
        {
        }

        public GroupedConfigSettings(string group, ISettings settings)
        {
            if (string.IsNullOrEmpty(group)) throw new ArgumentNullException(nameof(group));
            _group = group;

            _settings = settings ?? throw new ArgumentNullException(nameof(settings));
        }

        public virtual string this[string key]
        {
            get => _settings[BuildKey(key)];
            set => _settings[BuildKey(key)] = value;
        }

        public virtual void Delete(string key)
        {
            _settings.Delete(BuildKey(key));
        }

        public virtual T GetValueOrDefault<T>(string key, T defaultValue)
        {
            return _settings.GetValueOrDefault(BuildKey(key), defaultValue);
        }

        public virtual T GetValueOrDefault<T>(string key)
        {
            return _settings.GetValueOrDefault<T>(BuildKey(key));
        }

        public virtual void SetValue<T>(string key, T value)
        {
            _settings.SetValue(BuildKey(key), value);
        }

        string BuildKey(string key)
        {
            return $"{_group}.{key}";
        }
    }
}