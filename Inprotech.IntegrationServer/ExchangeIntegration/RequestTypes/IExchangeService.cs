using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes
{
    public interface IExchangeService : IContextualLogger
    {
        Task CreateOrUpdateAppointment(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId);
        Task CreateOrUpdateTask(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId);
        Task UpdateAppointment(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId);
        Task UpdateTask(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId);
        Task DeleteAppointment(ExchangeConfigurationSettings settings, int staffId, DateTime dateKey, string mailbox, int userId);
        Task DeleteTask(ExchangeConfigurationSettings settings, int staffId, DateTime dateKey, string mailbox, int userId);
        Task<bool> CheckStatus(ExchangeConfigurationSettings settings, string mailbox, int userId);
        Task SaveDraftEmail(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId);
    }
}