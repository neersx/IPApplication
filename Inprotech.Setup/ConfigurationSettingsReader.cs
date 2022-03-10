using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Setup.Core;

namespace Inprotech.Setup
{
    public interface IConfigurationSettingsReader
    {
        Task<IpPlatformAllSettings> GetIpPlatformSettings();
    }

    internal class ConfigurationSettingsReader : IConfigurationSettingsReader
    {
        readonly IAppConfigReader _appConfigReader;
        readonly IInprotechServerPersistingConfigManager _inprotechServerPersistingConfigManager;

        public ConfigurationSettingsReader(IInprotechServerPersistingConfigManager inprotechServerPersistingConfigManager, IAppConfigReader appConfigReader)
        {
            _inprotechServerPersistingConfigManager = inprotechServerPersistingConfigManager;
            _appConfigReader = appConfigReader;
        }

        public async Task<IpPlatformAllSettings> GetIpPlatformSettings()
        {
            var allSettings = new IpPlatformAllSettings
            {
                PersistedSettings = await GetPersistedIpPlatformSettings(),
                ConfigSettings = _appConfigReader.IpPlatformSettings()
            };

            return allSettings;
        }

        async Task<IpPlatformSettings> GetPersistedIpPlatformSettings()
        {
            var connectionString = Context.ResolvedIisApp.WebConfig.InprotechConnectionString;
            return await _inprotechServerPersistingConfigManager.GetIpPlatformSettings(connectionString, _appConfigReader.PrivateKey());
        }
    }

    public class IpPlatformAllSettings
    {
        public IpPlatformSettings PersistedSettings { get; internal set; }

        public Dictionary<string, string> ConfigSettings { get; internal set; }
    }
}