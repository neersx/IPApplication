using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.SaveDraftEmails
{
    public class SaveDraftEmailRequestHandler : IHandleExchangeMessage
    {
        readonly IDbContext _dbContext;
        readonly IBackgroundProcessLogger<SaveDraftEmailRequestHandler> _logger;
        readonly IStrategy _strategy;

        public SaveDraftEmailRequestHandler(IDbContext dbContext, IStrategy strategy, IBackgroundProcessLogger<SaveDraftEmailRequestHandler> logger)
        {
            _dbContext = dbContext;
            _strategy = strategy;
            _logger = logger;
        }

        public async Task<ExchangeProcessResult> Process(ExchangeRequest exchangeMessage, ExchangeConfigurationSettings settings)
        {
            if (exchangeMessage == null) throw new ArgumentNullException(nameof(exchangeMessage));
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            try
            {
                var exchangeService = _strategy.GetService(exchangeMessage.Context, settings.ServiceType);

                var exchangeItemRequest = await (from e in _dbContext.Set<ExchangeRequestQueueItem>()
                                                 where e.Id == exchangeMessage.Id
                                                 select new ExchangeItemRequest
                                                 {
                                                     Mailbox = e.MailBox,
                                                     RecipientEmail = e.Recipients,
                                                     CcRecipientEmails = e.CcRecipients,
                                                     BccRecipientEmails = e.BccRecipients,
                                                     Subject = e.Subject,
                                                     Body = e.Body,
                                                     IsBodyHtml = e.IsBodyHtml,
                                                     Attachments = e.Attachments
                                                 }).SingleAsync();

                _logger.Trace($"Dispatching {exchangeMessage.Id} to exchange service");

                await exchangeService.SaveDraftEmail(settings, exchangeItemRequest, exchangeMessage.UserId.Value);

                _logger.Trace($"Saved {exchangeMessage.Id} as email draft");

                return new ExchangeProcessResult {Result = KnownStatuses.Success};
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
    }
}