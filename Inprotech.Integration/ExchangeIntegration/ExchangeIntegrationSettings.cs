using System.Configuration;
using System.Linq;
using Inprotech.Contracts;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace Inprotech.Integration.ExchangeIntegration
{
    public class ExchangeIntegrationSettings : IExchangeIntegrationSettings
    {
        readonly IDbContext _dbContext;
        readonly ICryptoService _service;

        public ExchangeIntegrationSettings(IDbContext dbContext, ICryptoService service)
        {
            _dbContext = dbContext;
            _service = service;
        }

        public ExchangeConfigurationSettings Resolve()
        {
            var externalSetting = _dbContext.Set<ExternalSettings>().Single(s => s.ProviderName == KnownExternalSettings.ExchangeSetting);
            var setting = JsonConvert.DeserializeObject<ExchangeConfigurationSettings>(externalSetting.Settings);

            if (!setting.IsReminderEnabled && !setting.IsDraftEmailEnabled && !setting.IsBillFinalisationEnabled)
            {
                return new ExchangeConfigurationSettings(){ ExchangeGraph = new ExchangeGraph()};
            }

            if (setting.ServiceType == "Graph")
            {
                if (string.IsNullOrWhiteSpace(setting.ExchangeGraph.TenantId))
                {
                    throw new ConfigurationErrorsException("Exchange Graph Tenant ID has not been set.");
                }

                if (string.IsNullOrWhiteSpace(setting.ExchangeGraph.ClientId))
                {
                    throw new ConfigurationErrorsException("Exchange Graph Client ID has not been set.");
                }

                if (string.IsNullOrWhiteSpace(setting.ExchangeGraph.ClientSecret))
                {
                    throw new ConfigurationErrorsException("Exchange Graph Client Secret has not been set.");
                }
            }
            else
            {
                if (string.IsNullOrWhiteSpace(setting.Password))
                {
                    throw new ConfigurationErrorsException("Exchange Account Password has not been set.");
                }

                if (string.IsNullOrWhiteSpace(setting.Server))
                {
                    throw new ConfigurationErrorsException("Exchange Server URL has not been set.");
                }

                if (string.IsNullOrWhiteSpace(setting.UserName))
                {
                    throw new ConfigurationErrorsException("Exchange Account User ID has not been set.");
                }
            }

            return PopulateExchangeConfigurationSettings(setting);
        }

        public ExchangeConfigurationSettings ForEndpointTest()
        {
            var externalSetting = _dbContext.Set<ExternalSettings>().Single(s => s.ProviderName == KnownExternalSettings.ExchangeSetting);
            var setting = JsonConvert.DeserializeObject<ExchangeConfigurationSettings>(externalSetting.Settings);
            return PopulateExchangeConfigurationSettings(setting);
        }

        ExchangeConfigurationSettings PopulateExchangeConfigurationSettings(ExchangeConfigurationSettings setting)
        {
            return new ExchangeConfigurationSettings
            {
                Server = setting.Server,
                Domain = setting.Domain,
                UserName = setting.UserName,
                Password = string.IsNullOrWhiteSpace(setting.Password) ? string.Empty : _service.Decrypt(setting.Password),
                ServiceType = setting.ServiceType,
                ExchangeGraph = setting.ExchangeGraph != null ? new ExchangeGraph()
                {
                    ClientId = setting.ExchangeGraph.ClientId,
                    ClientSecret = string.IsNullOrWhiteSpace(setting.ExchangeGraph.ClientSecret) ? string.Empty : _service.Decrypt(setting.ExchangeGraph.ClientSecret),
                    TenantId = setting.ExchangeGraph.TenantId
                }
                    : null,
                IsDraftEmailEnabled = setting.IsDraftEmailEnabled,
                IsBillFinalisationEnabled = setting.IsBillFinalisationEnabled,
                IsReminderEnabled = setting.IsReminderEnabled,
                SupressConsentPrompt = setting.SupressConsentPrompt,
                RefreshTokenNotRequired = setting.RefreshTokenNotRequired
            };
        }

    }
}