using System.Configuration;

namespace Inprotech.Infrastructure.ConfigurationSetting
{
    public class GzipCompressionSection : ConfigurationSection
    {
        [ConfigurationProperty("enabled", DefaultValue = true, IsRequired = true)]
        public bool Enabled => (bool) this["enabled"];

        [ConfigurationProperty("minimumSizeToCompress", DefaultValue = (long)1000, IsRequired = true)]
        public long MinimumSizeToCompress => (long)this["minimumSizeToCompress"];
    }
}
