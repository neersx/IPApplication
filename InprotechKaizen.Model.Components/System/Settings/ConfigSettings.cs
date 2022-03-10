using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Settings;

namespace InprotechKaizen.Model.Components.System.Settings
{
    public class ConfigSettings : IConfigSettings
    {
        readonly IDbContext _dbContext;

        public ConfigSettings(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [SuppressMessage("Microsoft.Design",
            "CA1065:DoNotRaiseExceptionsInUnexpectedLocations")]
        public string this[string key]
        {
            get
            {
                if (string.IsNullOrEmpty(key)) throw new IndexOutOfRangeException("key is null or empty");
                return
                    _dbContext.Set<ConfigSetting>()
                              .Where(s => s.Key.Equals(key, StringComparison.OrdinalIgnoreCase))
                              .Select(s => s.Value)
                              .SingleOrDefault();
            }
            set
            {
                if (string.IsNullOrEmpty(key)) throw new IndexOutOfRangeException("key is null or empty");
                var setting =
                    _dbContext.Set<ConfigSetting>()
                              .SingleOrDefault(s => s.Key.Equals(key, StringComparison.OrdinalIgnoreCase));
                if (setting == null)
                {
                    setting = _dbContext.Set<ConfigSetting>().Add(new ConfigSetting(key));
                }

                setting.Value = value ?? throw new ArgumentNullException(nameof(value));
                _dbContext.SaveChanges();
            }
        }

        public void Delete(string key)
        {
            if (string.IsNullOrEmpty(key)) throw new ArgumentNullException(nameof(key));

            var setting = _dbContext.Set<ConfigSetting>()
                                    .SingleOrDefault(s => s.Key.Equals(key, StringComparison.OrdinalIgnoreCase));

            if (setting != null)
            {
                _dbContext.Set<ConfigSetting>().Remove(setting);
                _dbContext.SaveChanges();
            }
        }

        public T GetValueOrDefault<T>(string key, T defaultValue)
        {
            var converter = TypeDescriptor.GetConverter(typeof(T));

            try
            {
                var k = this[key];
                return (T) converter.ConvertFromInvariantString(k);
            }
            catch (NotSupportedException e)
            {
            }
            catch (FormatException f)
            {
            }

            return defaultValue;
        }

        public T GetValueOrDefault<T>(string key)
        {
            return GetValueOrDefault(key, default(T));
        }

        public void SetValue<T>(string key, T value)
        {
            var converter = TypeDescriptor.GetConverter(typeof(T));

            this[key] = converter.ConvertToInvariantString(value);
        }

        public Dictionary<string, string> GetValues(params string[] keys)
        {
            return _dbContext.Set<ConfigSetting>()
                             .Where(s => keys.Any(k => k.Equals(s.Key, StringComparison.OrdinalIgnoreCase)))
                             .ToDictionary(k => k.Key, v => v.Value);
        }
    }
}