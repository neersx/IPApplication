using System.Collections.Generic;
using System.Configuration;

namespace Inprotech.Setup.IpPlatformTester
{
    public interface IConfigurationSettings
    {
        string this[string index] { get; }
        void AddOrUpdateAppSetting(Dictionary<string, string> newValues);
    }

    public class ConfigurationSettings : IConfigurationSettings
    {
        public string this[string index] => ConfigurationManager.AppSettings[index];

        public void AddOrUpdateAppSetting(Dictionary<string, string> newValues)
        {
            var configFile = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);

            var settings = configFile.AppSettings.Settings;

            foreach (var newValue in newValues)
            {
                if (settings[newValue.Key] == null)
                {
                    settings.Add(newValue.Key, newValue.Value);
                }
                else
                {
                    settings[newValue.Key].Value = newValue.Value;
                }
            }
            if(!configFile.AppSettings.SectionInformation.IsProtected)
                configFile.AppSettings.SectionInformation.ProtectSection("DataProtectionConfigurationProvider");
            configFile.Save(ConfigurationSaveMode.Modified);
            ConfigurationManager.RefreshSection(configFile.AppSettings.SectionInformation.Name);
        }
    }
}
