using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;

namespace InprotechKaizen.Model.Components.System.Settings
{
    internal class GroupedConfig : IGroupedConfig
    {
        readonly string _group;
        readonly IConfigSettings _settings;

        public GroupedConfig(string group, IConfigSettings settings)
        {
            if (string.IsNullOrEmpty(group)) throw new ArgumentNullException(nameof(group));
            _settings = settings ?? throw new ArgumentNullException(nameof(settings));
            _group = group;
        }

        public string this[string key]
        {
            get => _settings[BuildKey(key)];
            set => _settings[BuildKey(key)] = value;
        }

        public void Delete(string key)
        {
            _settings.Delete(BuildKey(key));
        }

        public T GetValueOrDefault<T>(string key, T defaultValue)
        {
            return _settings.GetValueOrDefault(BuildKey(key), defaultValue);
        }

        public T GetValueOrDefault<T>(string key)
        {
            return _settings.GetValueOrDefault<T>(BuildKey(key));
        }

        public void SetValue<T>(string key, T value)
        {
            _settings.SetValue(BuildKey(key), value);
        }

        public Dictionary<string, string> GetValues(params string[] settings)
        {
            var records = _settings.GetValues(settings.Select(BuildKey).ToArray());
            return records.ToDictionary(k => RemoveKey(k.Key), v => v.Value);
        }

        string BuildKey(string key)
        {
            return $"{_group}.{key}";
        }

        string RemoveKey(string key)
        {
            return key.Replace($"{_group}.", string.Empty);
        }
    }
}