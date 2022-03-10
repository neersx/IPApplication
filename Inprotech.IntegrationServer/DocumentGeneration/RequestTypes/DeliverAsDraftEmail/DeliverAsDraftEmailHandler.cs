using System;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Contracts;
using Inprotech.Integration.ExchangeIntegration;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.DeliverAsDraftEmail
{
    public class DeliverAsDraftEmailHandler : IHandleDocGenRequest
    {
        readonly IDbContext _dbContext;
        readonly IDraftEmail _draftEmail;
        readonly IDraftEmailValidator _draftEmailValidator;
        readonly IExchangeIntegrationQueue _exchangeIntegrationQueue;
        readonly IExchangeIntegrationSettings _exchangeIntegrationSettings;
        readonly IBackgroundProcessLogger<DeliverAsDraftEmailHandler> _logger;

        public DeliverAsDraftEmailHandler(IBackgroundProcessLogger<DeliverAsDraftEmailHandler> logger, IDbContext dbContext, IDraftEmail draftEmail, IDraftEmailValidator draftEmailValidator, IExchangeIntegrationQueue exchangeIntegrationQueue, IExchangeIntegrationSettings exchangeIntegrationSettings)
        {
            _logger = logger;
            _dbContext = dbContext;
            _draftEmail = draftEmail;
            _draftEmailValidator = draftEmailValidator;
            _exchangeIntegrationQueue = exchangeIntegrationQueue;
            _exchangeIntegrationSettings = exchangeIntegrationSettings;
        }

        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);
        }

        public async Task<DocGenProcessResult> Handle(DocGenRequest docGenRequest)
        {
            if (docGenRequest == null) throw new ArgumentNullException(nameof(docGenRequest));
            
            if (!_exchangeIntegrationSettings.Resolve().IsDraftEmailEnabled)
            {
                return new DocGenProcessResult
                {
                    ErrorMessage = "Exchange Integration has not been enabled for 'Send as Draft Email'",
                    Result = KnownStatuses.Failed
                };
            }
            
            _logger.Trace($"Preparing draft email for {docGenRequest.Id}");

            var prepared = await _draftEmail.Prepare(docGenRequest);
            
            _logger.Trace($"Draft email for {docGenRequest.Id} sent for validation");

            _draftEmailValidator.EnsureValid(prepared);

            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                _logger.Trace("Enqueue draft email request");

                await _exchangeIntegrationQueue.QueueDraftEmailRequest(prepared, docGenRequest.Id);
                
                await _dbContext.SaveChangesAsync();

                tcs.Complete();
            }
            
            _logger.Trace($"Email for {docGenRequest.Id} queued for delivery");

            return new DocGenProcessResult {Result = KnownStatuses.Success};
        }
    }
}