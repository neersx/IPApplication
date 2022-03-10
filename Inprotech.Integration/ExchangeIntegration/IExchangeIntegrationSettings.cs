using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.Integration.ExchangeIntegration
{
    public interface IExchangeIntegrationSettings
    {
        ExchangeConfigurationSettings Resolve();
        ExchangeConfigurationSettings ForEndpointTest();
    }
}