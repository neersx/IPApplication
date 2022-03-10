using System.Data.Entity;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.System.Settings
{
    public interface IExternalSettings
    {
        Task<T> Resolve<T>(string externalSettingKey);
        Task AddUpdate(string externalSettingKey, string settingJson, bool isComplete = true);
    }

    class ExternalSetting : IExternalSettings
    {
        readonly IDbContext _dbContext;
        readonly ICryptoService _cryptoService;

        public ExternalSetting(IDbContext dbContext, ICryptoService cryptoService)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
        }

        public async Task<T> Resolve<T>(string externalSettingKey)
        {
            var settings = await GetSettings<T>(externalSettingKey);
            return settings;
        }

        public async Task AddUpdate(string externalSettingKey, string settingJson, bool isComplete = true)
        {
            var encrypted = _cryptoService.Encrypt(settingJson);
            var es = _dbContext.Set<ExternalSettings>();
            var setting = await es.SingleOrDefaultAsync(_ => _.ProviderName == externalSettingKey) ?? es.Add(new ExternalSettings(externalSettingKey));

            setting.Settings = encrypted;
            setting.IsComplete = isComplete;
            await _dbContext.SaveChangesAsync();
        }

        async Task<T> GetSettings<T>(string externalSettingKey)
        {
            var setting = await GetExternalSettingsClearText(externalSettingKey, true);

            return string.IsNullOrWhiteSpace(setting)
                ? default(T)
                : JsonConvert.DeserializeObject<T>(setting);
        }

        async Task<string> GetExternalSettingsClearText(string providerName, bool decrypt)
        {
            var setting = (await _dbContext.Set<ExternalSettings>()
                                           .SingleOrDefaultAsync(_ => _.ProviderName == providerName))?.Settings;

            return decrypt && !string.IsNullOrWhiteSpace(setting)
                ? _cryptoService.Decrypt(setting)
                : setting;
        }
    }
}