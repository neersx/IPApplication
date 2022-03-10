using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public interface IDmsSettingsProvider
    {
        Task<DmsSettings> Provide();
        Task<IEnumerable<IManageSettings.SiteDatabaseSettings>> OAuth2Setting();
        Task<bool> HasSettings();
    }

    public class DmsSettingsProvider : IDmsSettingsProvider
    {
        readonly IConfiguredDms _configuredDms;
        readonly ICryptoService _cryptoService;
        readonly IDbContext _dbContext;

        public DmsSettingsProvider(IDbContext dbContext, IConfiguredDms configuredDms, ICryptoService cryptoService)
        {
            _dbContext = dbContext;
            _configuredDms = configuredDms;
            _cryptoService = cryptoService;
        }

        public async Task<DmsSettings> Provide()
        {
            var settingMetaData = _configuredDms.GetSettingMetaData();

            var setting = await _dbContext.Set<ExternalSettings>()
                                          .SingleOrDefaultAsync(_ => _.ProviderName == settingMetaData.Name);

            if (setting == null || string.IsNullOrWhiteSpace(setting.Settings))
            {
                return new DmsSettings();
            }

            var settings = JsonConvert.DeserializeObject(_cryptoService.Decrypt(setting.Settings), settingMetaData.Type) as IManageSettings;
            settings.Disabled = setting.IsDisabled;

            return settings;
        }

        public async Task<bool> HasSettings()
        {
            return await Provide() is IManageSettings settingObject && settingObject.Databases.Any() && !settingObject.Disabled;
        }

        public async Task<IEnumerable<IManageSettings.SiteDatabaseSettings>> OAuth2Setting()
        {
            var settingMetaData = _configuredDms.GetSettingMetaData();

            var setting = await _dbContext.Set<ExternalSettings>()
                                          .SingleOrDefaultAsync(_ => _.ProviderName == settingMetaData.Name);

            if (setting == null || string.IsNullOrWhiteSpace(setting.Settings))
            {
                return null;
            }

            var settings = JsonConvert.DeserializeObject(_cryptoService.Decrypt(setting.Settings), settingMetaData.Type) as IManageSettings;

            return settings?.Databases.Where(d => d.IntegrationType == IManageSettings.IntegrationTypes.iManageWorkApiV2);
        }
    }
}