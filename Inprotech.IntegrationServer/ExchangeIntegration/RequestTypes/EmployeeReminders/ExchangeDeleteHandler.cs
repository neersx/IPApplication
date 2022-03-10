using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class ExchangeDeleteHandler : IHandleExchangeMessage
    {
        readonly IStrategy _strategy;
        readonly IUserFormatter _userFormatter;
        readonly IIntegrationValidator _integrationValidator;
        readonly IBackgroundProcessLogger<IHandleExchangeMessage> _logger;
        public ExchangeDeleteHandler(IStrategy strategy, IUserFormatter userFormatter, IIntegrationValidator integrationValidator, IBackgroundProcessLogger<IHandleExchangeMessage> logger)
        {
            _strategy = strategy;
            _userFormatter = userFormatter;
            _integrationValidator = integrationValidator;
            _logger = logger;
        }

        public async Task<ExchangeProcessResult> Process(ExchangeRequest request, ExchangeConfigurationSettings settings)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            try
            {
                var exchangeService = _strategy.GetService(request.Context, settings.ServiceType);

                var exchangeUsers = _userFormatter.Users(request.StaffId);
                var users = _integrationValidator.ValidUsersForIntegration(request, exchangeUsers).ToArray();
                
                foreach (var user in users)
                {
                    await exchangeService.DeleteAppointment(settings, request.StaffId, request.SequenceDate, user.Mailbox, user.UserIdentityId);

                    await exchangeService.DeleteTask(settings, request.StaffId, request.SequenceDate, user.Mailbox, user.UserIdentityId);
                }

                _logger.Trace($"Exchange items deleted for users {users.Length}");

                return new ExchangeProcessResult { Result = KnownStatuses.Success };
            }
            catch (Exception ex)
            {
                _logger.Exception(ex);
                return new ExchangeProcessResult { Result = KnownStatuses.Failed, ErrorMessage = ex.Message };
            }
        }
        
        public void SetLogContext(Guid context)
        {
            _logger.SetContext(context);
        }
    }
}