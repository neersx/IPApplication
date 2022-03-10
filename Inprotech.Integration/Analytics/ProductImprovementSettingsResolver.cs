using System;
using Inprotech.Infrastructure;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Analytics
{
    public interface IProductImprovementSettingsResolver
    {
        ProductImprovementSettings Resolve();
    }

    public class ProductImprovementSettingsResolver : IProductImprovementSettingsResolver
    {
        readonly Func<string, IGroupedConfig> _groupedConfig;
        ProductImprovementSettings _settings;

        public ProductImprovementSettingsResolver(Func<string, IGroupedConfig> groupedConfig)
        {
            _groupedConfig = groupedConfig;
        }

        public ProductImprovementSettings Resolve()
        {
            if (_settings == null)
            {
                var settings = _groupedConfig("InprotechServer.AppSettings").GetValues(KnownAppSettingsKeys.ProductImprovement);

                if (settings.ContainsKey(KnownAppSettingsKeys.ProductImprovement))
                {
                    var deserialized = JsonConvert.DeserializeObject<JObject>(settings[KnownAppSettingsKeys.ProductImprovement]);

                    _settings = new ProductImprovementSettings
                    {
                        UserUsageStatisticsConsented = (bool?) deserialized?["UserUsageStatisticsConsented"] ?? false,
                        FirmUsageStatisticsConsented = (bool?) deserialized?["FirmUsageStatisticsConsented"] ?? false
                    };
                }
                else
                {
                    _settings = new ProductImprovementSettings();
                }
            }

            return _settings;
        }
    }

    public class ProductImprovementSettings
    {
        public bool UserUsageStatisticsConsented { get; set; }

        public bool FirmUsageStatisticsConsented { get; set; }
    }
}