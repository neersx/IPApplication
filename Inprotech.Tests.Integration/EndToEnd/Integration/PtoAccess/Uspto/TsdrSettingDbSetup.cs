using System.Linq;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Integration.DbHelpers;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess.Uspto
{
    public static class TsdrSecret
    {
        public const string ApiKey = "0u9SfwzEHE1Yt0R13xcNdAH0rbrGxtWi";
        public const string EncryptedApiKey = "YtIpr6UpqccKTXm+Fj6eW1NVyhuWr2NXyRb01pVy4iHmCz1kOgTWA0n2qteSmGZs";
        public const string SettingKey = "TsdrIntegration.ApiKey";
    }

    public class TsdrSettingDbSetup : IntegrationDbSetup
    {
        public void EnsureEmptyConfiguration()
        {
            var setting = IntegrationDbContext.Set<ConfigSetting>().SingleOrDefault(_ => _.Key == TsdrSecret.SettingKey);
            if (setting != null)
            {
                IntegrationDbContext.Set<ConfigSetting>().Remove(setting);
                IntegrationDbContext.SaveChanges();
            }
        }

        public void EnsureValidConfiguration()
        {
            var setting = IntegrationDbContext.Set<ConfigSetting>().SingleOrDefault(_ => _.Key == TsdrSecret.SettingKey);
            if (setting == null)
            {
                setting = new ConfigSetting(TsdrSecret.SettingKey) {Value = TsdrSecret.EncryptedApiKey};
                IntegrationDbContext.Set<ConfigSetting>().Add(setting);
            }
            else
            {
                setting.Value = TsdrSecret.EncryptedApiKey;
            }

            IntegrationDbContext.SaveChanges();
        }
    }
}
