using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Profiles;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class ExchangeIntegrationInitialiser : IHandleExchangeMessage
    {
        readonly IStrategy _strategy;
        readonly IReminderDetails _reminderDetails;
        readonly IUserPreferenceManager _userPreferenceManager;
        readonly IBackgroundProcessLogger<IHandleExchangeMessage> _logger;

        public ExchangeIntegrationInitialiser(IStrategy strategy, IReminderDetails reminderDetails, IUserPreferenceManager userPreferenceManager, IBackgroundProcessLogger<IHandleExchangeMessage> logger)
        {
            _strategy = strategy;
            _reminderDetails = reminderDetails;
            _userPreferenceManager = userPreferenceManager;
            _logger = logger;
        }

        public async Task<ExchangeProcessResult> Process(ExchangeRequest request, ExchangeConfigurationSettings settings)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            try
            {
                var exchangeService = _strategy.GetService(request.Context, settings.ServiceType);

                if (request.UserId == null)
                    return new ExchangeProcessResult { Result = KnownStatuses.Success };

                var userAndRemindersDetail = _reminderDetails.ForUsers(request.StaffId, request.UserId.Value, request.SequenceDate);
                if (!userAndRemindersDetail.ReminderDetails.Any())
                    return new ExchangeProcessResult { Result = KnownStatuses.Obsolete, ErrorMessage = "The request failed as the associated reminder has changed. Delete the request." };

                if (!userAndRemindersDetail.Users.Any())
                    return new ExchangeProcessResult { Result = KnownStatuses.Failed, ErrorMessage = "This staff has not been configured for Exchange Integration." };

                var user = userAndRemindersDetail.Users.First();

                foreach (var r in userAndRemindersDetail.ReminderDetails)
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

                    await exchangeService.CreateOrUpdateAppointment(settings, exchangeItemRequest, user.UserIdentityId);

                    await exchangeService.CreateOrUpdateTask(settings, exchangeItemRequest, user.UserIdentityId);

                    _userPreferenceManager.SetPreference(request.UserId.Value, KnownSettingIds.IsExchangeInitialised, true);
                }

                _logger.Trace($"Exchange items created for user {userAndRemindersDetail.ReminderDetails.Count()}, UserId={user.UserIdentityId}, mailbox={user.Mailbox}");

                return new ExchangeProcessResult {Result = KnownStatuses.Success };
            }
            catch (Exception ex)
            {
                _logger.Exception(ex);
                return new ExchangeProcessResult {Result = KnownStatuses.Failed, ErrorMessage = ex.Message};
            }
        }
        
        public void SetLogContext(Guid context)
        {
            _logger.SetContext(context);
        }

        static DateTime? AdjustDateWithAlertTimeOfDay(DateTime? due, TimeSpan timeForAlert)
        {
            return due?.Date + timeForAlert;
        }
    }
}
