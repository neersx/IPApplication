using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Profiles
{
    public class UserPreferenceManager : IUserPreferenceManager
    {
        readonly IPreferredCultureResolver _culture;
        readonly IDbContext _dbContext;

        public UserPreferenceManager(IDbContext dbContext, IPreferredCultureResolver culture)
        {
            _dbContext = dbContext;
            _culture = culture;
        }

        public void SetPreference<T>(int userId, int setting, T value)
        {
            var user = GetUser(userId);
            object objValue = value;

            var userInitSetting = _dbContext.Set<SettingValues>().SingleOrDefault(v => v.User.Id == userId && v.SettingId == setting);
            if (userInitSetting != null)
            {
                if (typeof(T) == typeof(bool) || typeof(T) == typeof(bool?))
                {
                    userInitSetting.BooleanValue = (bool?) objValue;
                }
                else if (typeof(T) == typeof(string))
                {
                    userInitSetting.CharacterValue = (string) objValue;
                }
                else if (typeof(T) == typeof(int) || typeof(T) == typeof(int?))
                {
                    userInitSetting.IntegerValue = (int?) objValue;
                }
                else if (typeof(T) == typeof(decimal) || typeof(T) == typeof(decimal?))
                {
                    userInitSetting.DecimalValue = (decimal?) objValue;
                }
            }
            else
            {
                if (typeof(T) == typeof(bool) || typeof(T) == typeof(bool?))
                {
                    _dbContext.Set<SettingValues>().Add(new SettingValues {BooleanValue = (bool?) objValue, SettingId = setting, User = user});
                }
                else if (typeof(T) == typeof(string))
                {
                    _dbContext.Set<SettingValues>().Add(new SettingValues {CharacterValue = (string) objValue, SettingId = setting, User = user});
                }
                else if (typeof(T) == typeof(int) || typeof(T) == typeof(int?))
                {
                    _dbContext.Set<SettingValues>().Add(new SettingValues {IntegerValue = (int?) objValue, SettingId = setting, User = user});
                }
                else if (typeof(T) == typeof(decimal) || typeof(T) == typeof(decimal?))
                {
                    _dbContext.Set<SettingValues>().Add(new SettingValues {DecimalValue = (decimal?) objValue, SettingId = setting, User = user});
                }
            }

            _dbContext.SaveChanges();
        }

        public T GetPreference<T>(int userId, int setting)
        {
            var sv = _dbContext.Set<SettingValues>()
                               .Where(v => (v.User == null || v.User.Id == userId) && v.SettingId == setting)
                               .OrderByDescending(_ => _.User != null)
                               .FirstOrDefault();

            return (sv == null)
                ? default
                : (T) ConvertSettingValuesValue(typeof(T), sv);
        }

        public async Task<T[]> GetPreferences<T>(int userId, int[] settingIds) where T : class, new()
        {
            var culture = _culture.Resolve();
            var settings = await (from _ in _dbContext.Set<SettingValues>()
                                join d in _dbContext.Set<SettingDefinition>() on _.SettingId equals d.SettingId
                                where (_.User == null || _.User.Id == userId) && settingIds.Contains(_.SettingId)
                                select new UserPreference
                                {
                                    BooleanValue = _.BooleanValue,
                                    IntegerValue = _.IntegerValue,
                                    Id = _.SettingId,
                                    Name = DbFuncs.GetTranslation(_.Definition.Name, null, _.Definition.NameTid, culture),
                                    Description = DbFuncs.GetTranslation(_.Definition.Description, null, _.Definition.DescriptionTid, culture),
                                    IsDefault = _.User == null,
                                    DataType = d.DataType
                                }).ToArrayAsync();
            var defaultSettings = settings.Where(_ => _.IsDefault).ToArray();
            var userSettings = settings.GroupBy(_ => _.Id).Select(_ => _.OrderBy(x => x.IsDefault).FirstOrDefault()).ToArray();
            foreach (var userPreference in userSettings)
            {
                var defaultSetting = defaultSettings.FirstOrDefault(_ => _.Id == userPreference.Id);
                userPreference.DefaultBooleanValue = defaultSetting?.BooleanValue ?? false;
                userPreference.DefaultIntegerValue = defaultSetting?.IntegerValue;
            }
            return userSettings as T[];
        }

        public void ResetUserPreferences(int userId, int[] settingIds)
        {
            var settings = _dbContext.Set<SettingValues>()
                                    .Where(v => (v.User != null && v.User.Id == userId) && settingIds.Contains(v.SettingId)).ToArray();
            foreach (var setting in settings) 
                _dbContext.Set<SettingValues>().Remove(setting);

            _dbContext.SaveChanges();
        }
        
        User GetUser(int userId)
        {
            return _dbContext.Set<User>().Single(v => v.Id == userId);
        }

        static object ConvertSettingValuesValue(Type type, SettingValues settingValues)
        {
            if (type == typeof(int?))
            {
                return settingValues?.IntegerValue;
            }

            if (type == typeof(bool?))
            {
                return settingValues?.BooleanValue;
            }
            
            if (type == typeof(decimal?))
            {
                return settingValues?.DecimalValue;
            }

            if (type == typeof(string))
            {
                return settingValues?.CharacterValue;
            }

            if (type == typeof(int))
            {
                return settingValues?.IntegerValue ?? 0;
            }

            if (type == typeof(decimal))
            {
                return settingValues?.DecimalValue ?? 0;
            }

            if (type == typeof(bool))
            {
                return settingValues?.BooleanValue ?? false;
            }

            throw new ArgumentOutOfRangeException($"Could not find a matching SettingValues value for type: {type}");
        }
    }

    public class UserPreference
    {
        public int Id { get; set; }
        public bool? BooleanValue { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public bool IsDefault { get; set; }
        public bool? DefaultBooleanValue { get; set; }
        public int? IntegerValue { get; set; }
        public int? DefaultIntegerValue { get; set; }
        public string DataType { get; set; }
    }
}