using System.Linq;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Integration.DbHelpers;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.PtoSettings.Epo
{
    public static class EpoKeys
    {
        public const string ConsumerKey = "qXZ9pDiwOPd8dOSGMN6AhBZQZx2gLa0Y";
        public const string PrivateKey = "G9iFUk22MQ0Gikl0";
        public const string EncryptedKey = "B/Qket8TFcyt0TNMYUNwuSSy6k3Yc4HHd6VXoLsFelnUhJw2EIFHdBEfYBENJ+aGWxJJmv7+ubsB2lELX7SSgTWWmAFH5jw6I7vvQqZDNRT8WC6aW4Xm3eReOrTBOVZw";
        public const string SettingKey = "EpoIntegration.ConsumerKeys";
    }

    public class EpoSettingDbSetup : IntegrationDbSetup
    {
        public void EnsureEmptyConfiguration()
        {
            var setting = IntegrationDbContext.Set<ConfigSetting>().SingleOrDefault(_ => _.Key == EpoKeys.SettingKey);
            if (setting != null)
            {
                IntegrationDbContext.Set<ConfigSetting>().Remove(setting);
                IntegrationDbContext.SaveChanges();
            }
        }

        public void EnsureValidConfiguration()
        {
            var setting = IntegrationDbContext.Set<ConfigSetting>().SingleOrDefault(_ => _.Key == EpoKeys.SettingKey);
            if (setting == null)
            {
                setting = new ConfigSetting(EpoKeys.SettingKey) {Value = EpoKeys.EncryptedKey};
                IntegrationDbContext.Set<ConfigSetting>().Add(setting);
            }
            else
            {
                setting.Value = EpoKeys.EncryptedKey;
            }

            IntegrationDbContext.SaveChanges();
        }
    }
}