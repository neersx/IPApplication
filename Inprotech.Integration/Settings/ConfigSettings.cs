using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Inprotech.Contracts.Settings;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Settings
{
    [Table("ConfigurationSettings")]
    public class ConfigSetting
    {
        public ConfigSetting()
        {
        }

        public ConfigSetting(string key)
        {
            if (string.IsNullOrEmpty(key)) throw new ArgumentNullException("key");
            Key = key;
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public long Id { get; set; }

        [Index(IsUnique = true)]
        public string Key { get; set; }

        public string Value { get; set; }
    }

    public class ConfigSettings : ISettings
    {
        readonly IRepository _repository;

        public ConfigSettings(IRepository repository)
        {
            _repository = repository ?? throw new ArgumentNullException(nameof(repository));
        }

        [SuppressMessage("Microsoft.Design", "CA1065:DoNotRaiseExceptionsInUnexpectedLocations")]
        public string this[string key]
        {
            get
            {
                if (string.IsNullOrEmpty(key)) throw new IndexOutOfRangeException("key is null or empty");
                return
                    _repository.Set<ConfigSetting>()
                               .Where(s => s.Key.Equals(key, StringComparison.OrdinalIgnoreCase))
                               .Select(s => s.Value)
                               .SingleOrDefault();
            }
            set
            {
                if (value == null) throw new ArgumentNullException("value");
                if (string.IsNullOrEmpty(key)) throw new IndexOutOfRangeException("key is null or empty");
                var setting = _repository.Set<ConfigSetting>()
                                         .SingleOrDefault(s => s.Key.Equals(key, StringComparison.OrdinalIgnoreCase));
                if (setting != null && string.Equals(setting.Value, value, StringComparison.Ordinal))
                {
                    return;
                }

                if (setting == null)
                {
                    setting = _repository.Set<ConfigSetting>().Add(new ConfigSetting(key));
                }

                setting.Value = value;
                _repository.SaveChanges();
            }
        }

        public void Delete(string key)
        {
            if (string.IsNullOrEmpty(key)) throw new ArgumentNullException("key");

            var setting = _repository.Set<ConfigSetting>()
                                     .SingleOrDefault(s => s.Key.Equals(key, StringComparison.OrdinalIgnoreCase));

            if (setting != null)
            {
                _repository.Set<ConfigSetting>().Remove(setting);
                _repository.SaveChanges();
            }
        }

        public T GetValueOrDefault<T>(string key, T defaultValue)
        {
            var converter = TypeDescriptor.GetConverter(typeof(T));

            try
            {
                return (T) converter.ConvertFromInvariantString(this[key]);
            }
            catch (NotSupportedException)
            {
            }
            catch (FormatException)
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
    }
}