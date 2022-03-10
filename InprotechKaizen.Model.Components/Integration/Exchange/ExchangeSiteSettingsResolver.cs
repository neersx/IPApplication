using System.Data.Entity;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json.Linq;

namespace InprotechKaizen.Model.Components.Integration.Exchange
{
    public interface IExchangeSiteSettingsResolver
    {
        Task<ExchangeSiteSetting> Resolve();
    }

    public class ExchangeSiteSettingsResolver : IExchangeSiteSettingsResolver
    {
        readonly IDbContext _dbContext;

        public ExchangeSiteSettingsResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<ExchangeSiteSetting> Resolve()
        {
            var externalSetting = await _dbContext.Set<ExternalSettings>()
                                                  .SingleOrDefaultAsync(_ => _.ProviderName == KnownExternalSettings.ExchangeSetting);

            if (externalSetting == null)
            {
                return new ExchangeSiteSetting
                {
                    ExternalSettingExists = false
                };
            }

            var exchangeConfigurationSettings = JObject.Parse(externalSetting.Settings).ToObject<ExchangeConfigurationSettings>();

            return new ExchangeSiteSetting
            {
                ExternalSettingExists = true,
                Settings = exchangeConfigurationSettings,
                HasValidSettings = externalSetting.IsComplete
            };
        }
    }

    public class ExchangeSiteSetting
    {
        public bool ExternalSettingExists { get; set; }
        public ExchangeConfigurationSettings Settings { get; set; }
        public bool HasValidSettings { get; set; }
    }
}