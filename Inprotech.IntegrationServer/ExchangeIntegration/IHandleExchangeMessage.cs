using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.IntegrationServer.ExchangeIntegration
{
    public interface IHandleExchangeMessage : IContextualLogger
    {
        Task<ExchangeProcessResult> Process(ExchangeRequest exchangeMessage, ExchangeConfigurationSettings settings);
    }
}