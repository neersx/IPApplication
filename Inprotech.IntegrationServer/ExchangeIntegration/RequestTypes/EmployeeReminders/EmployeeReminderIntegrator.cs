using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class EmployeeReminderIntegrator : IHandleExchangeMessage
    {
        readonly IIntegrationValidator _integrationValidator;
        readonly IBackgroundProcessLogger<IHandleExchangeMessage> _logger;
        readonly IStrategy _strategy;
        readonly IReminderDetails _reminderDetails;

        public EmployeeReminderIntegrator(IStrategy strategy, IReminderDetails reminderDetails, IIntegrationValidator integrationValidator, IBackgroundProcessLogger<IHandleExchangeMessage> logger)
        {
            _strategy = strategy;
            _reminderDetails = reminderDetails;
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

                var usersAndReminderDetail = _reminderDetails.For(request.StaffId, request.SequenceDate);
                if (usersAndReminderDetail == null)
                {
                    return new ExchangeProcessResult {Result = KnownStatuses.Obsolete, ErrorMessage = "The request failed as the associated reminder has changed. Delete the request."};
                }

                var r = usersAndReminderDetail.ReminderDetails.FirstOrDefault();
                if (r == null)
                {
                    return new ExchangeProcessResult {Result = KnownStatuses.Obsolete, ErrorMessage = "The request failed as the associated reminder has changed. Delete the request."};
                }

                var users = _integrationValidator.ValidUsersForIntegration(request, usersAndReminderDetail.Users).ToArray();
                if (!users.Any())
                {
                    return new ExchangeProcessResult {Result = KnownStatuses.Failed, ErrorMessage = "This staff has not been configured for Exchange Integration."};
                }

                foreach (var user in users)
                {
                    var subject = string.IsNullOrEmpty(r.CaseReference) ? $"Ad Hoc Reminder {r.AlertReference}: {r.Message}" : $"Case {r.CaseReference}: {r.Message}";

                    var exchangeItemRequest = new ExchangeItemRequest
                    {
                        RecipientEmail = user.Mailbox,
                        Subject = subject,
                        Body = r.Comments,
                        StaffId = r.StaffId,
                        CreatedOn = r.DateCreated,
                        DueDate = AdjustDateWithAlertTimeOfDay(r.DueDate, user.AlertTime),
                        ReminderDate = AdjustDateWithAlertTimeOfDay(r.ReminderDate, user.AlertTime),
                        IsReminderRequired = user.IsAlertRequired,
                        IsHighPriority = r.IsHighPriority
                    };
                    
                    switch (request.RequestType)
                    {
                        case ExchangeRequestType.Add:
                            await exchangeService.CreateOrUpdateAppointment(settings, exchangeItemRequest, user.UserIdentityId);
                            await exchangeService.CreateOrUpdateTask(settings, exchangeItemRequest, user.UserIdentityId);
                            break;
                        case ExchangeRequestType.Update:
                            await exchangeService.UpdateAppointment(settings, exchangeItemRequest, user.UserIdentityId);
                            await exchangeService.UpdateTask(settings, exchangeItemRequest, user.UserIdentityId);
                            break;
                    }
                }

                _logger.Trace($"Exchange items created/updated for {users.Length} users. Ref={r.CaseReference ?? r.AlertReference}");

                return new ExchangeProcessResult {Result = KnownStatuses.Success};
            }
            catch (Exception ex)
            {
                _logger.Exception(ex);
                return new ExchangeProcessResult {Result = KnownStatuses.Failed, ErrorMessage = ex.Message};
            }
        }

        static DateTime? AdjustDateWithAlertTimeOfDay(DateTime? due, TimeSpan timeForAlert)
        {
            return due?.Date + timeForAlert;
        }

        public void SetLogContext(Guid context)
        {
            _logger.SetContext(context);
        }
    }
}