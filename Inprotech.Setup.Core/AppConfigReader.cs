using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;

namespace Inprotech.Setup.Core
{
    public interface IAppConfigReader
    {
        IDictionary<string, string> ReadInprotechServerAppSettings();

        IDictionary<string, string> ReadInprotechIntegrationAppSettings();

        IDictionary<string, string> ReadInprotechStorageServiceAppSettings();
        
        string PrivateKey();

        Dictionary<string, string> IpPlatformSettings();
    }

    public class AppConfigReader : IAppConfigReader
    {
        public IDictionary<string, string> ReadInprotechServerAppSettings()
        {
            var configPath = Path.Combine(Constants.ContentRoot, Constants.InprotechServer.Folder, Constants.InprotechServer.Exe);
            var config = ConfigurationManager.OpenExeConfiguration(configPath);
            var appSettings = config.AppSettings.Settings;
            return appSettings.AllKeys.ToDictionary(key => key, key => appSettings[key].Value);
        }

        public IDictionary<string, string> ReadInprotechIntegrationAppSettings()
        {
            var configPath = Path.Combine(Constants.ContentRoot, Constants.IntegrationServer.Folder, Constants.IntegrationServer.Exe);
            var config = ConfigurationManager.OpenExeConfiguration(configPath);
            var appSettings = config.AppSettings.Settings;
            return appSettings.AllKeys.ToDictionary(key => key, key => appSettings[key].Value);
        }

        public IDictionary<string, string> ReadInprotechStorageServiceAppSettings()
        {
            var configPath = Path.Combine(Constants.ContentRoot, Constants.StorageService.Folder, Constants.StorageService.Exe);
            var config = ConfigurationManager.OpenExeConfiguration(configPath);
            var appSettings = config.AppSettings.Settings;
            return appSettings.AllKeys.ToDictionary(key => key, key => appSettings[key].Value);
        }

        public string PrivateKey()
        {
            return ReadInprotechServerAppSettings()[Constants.AppSettings.InprotechServerSettings.PrivateKey];
        }
        
        public Dictionary<string, string> IpPlatformSettings()
        {
            var allIpPlatformKeys = ReadInprotechServerAppSettings().Where(_ => _.Key.StartsWith(Constants.IpPlatformSettings.Prefix) || _.Key.StartsWith(Constants.IpPlatformSettings.IamProxyPrefix));

            var allConfigSettings = allIpPlatformKeys.ToDictionary(ipKey => ipKey.Key, ipKey => ipKey.Value);

            if (!allConfigSettings.ContainsKey(Constants.IpPlatformSettings.ClientId))
            {
                allConfigSettings.Add(Constants.IpPlatformSettings.ClientId, string.Empty);
            }
            if (!allConfigSettings.ContainsKey(Constants.IpPlatformSettings.ClientSecret))
            {
                allConfigSettings.Add(Constants.IpPlatformSettings.ClientSecret, string.Empty);
            }

            return allConfigSettings;
        }
    }
}