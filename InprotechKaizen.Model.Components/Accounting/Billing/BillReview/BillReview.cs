using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Accounting.Billing.BillReview
{
    public interface IBillReview
    {
        Task SendBillsForReview(int userIdentityId, string culture, params BillGenerationRequest[] requests);
    }

    public class BillReview : IBillReview
    {
        readonly IDbContext _dbContext;
        readonly ILogger<BillReview> _logger;
        readonly IBillReviewSettingsResolver _settingsResolver;
        readonly IBillReviewEmailBuilder _reviewEmailBuilder;
        readonly IExchangeIntegrationQueue _exchangeIntegrationQueue;
        readonly IComponentResolver _componentResolver;
        readonly IContextInfo _contextInfo;

        public BillReview(
            IDbContext dbContext,
            ILogger<BillReview> logger,
            IBillReviewSettingsResolver settingsResolver,
            IBillReviewEmailBuilder reviewEmailBuilder,
            IExchangeIntegrationQueue exchangeIntegrationQueue,
            IComponentResolver componentResolver,
            IContextInfo contextInfo)
        {
            _dbContext = dbContext;
            _logger = logger;
            _settingsResolver = settingsResolver;
            _reviewEmailBuilder = reviewEmailBuilder;
            _exchangeIntegrationQueue = exchangeIntegrationQueue;
            _componentResolver = componentResolver;
            _contextInfo = contextInfo;
        }

        public async Task SendBillsForReview(int userIdentityId, string culture, params BillGenerationRequest[] requests)
        {
            if (!requests.Any())
            {
                return;
            }

            var settings = await _settingsResolver.Resolve(userIdentityId);
            if (string.IsNullOrWhiteSpace(settings.ReviewerMailbox))
            {
                _logger.Warning($"{nameof(SendBillsForReview)}: Unable to send bills for review.  Reviewer {userIdentityId} mailbox is unset ({settings.ReviewerMailbox}).");
                return;
            }
            
            if (!settings.CanReviewBillInEmailDraft && !string.IsNullOrWhiteSpace(settings.ReviewerMailbox))
            {
                _logger.Warning($"{nameof(SendBillsForReview)}: Unable to send bills for review.  'Review invoices in Billing' option must be set, and Exchange Integration settings must be configured.");
                return;
            }
            
            var drafts = await _reviewEmailBuilder.Build(userIdentityId, culture, settings.ReviewerMailbox, requests);
            
            var staffId = (await _dbContext.Set<User>().SingleAsync(_ => _.Id == userIdentityId)).NameId;

            var billingComponentId = _componentResolver.Resolve(KnownComponents.Billing);

            foreach (var draft in drafts)
            {
                await EnqueueReviewEmailDraft(userIdentityId, draft.Email, draft.Request, draft.FirstCaseIncluded, staffId, billingComponentId);
            }
        }

        async Task EnqueueReviewEmailDraft(int userIdentityId, DraftEmailProperties email, BillGenerationRequest request, int? firstCaseIncluded, int staffId, int? billingComponentId)
        {
            using var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);

            _contextInfo.EnsureUserContext(userIdentityId, componentId: billingComponentId);

            await _exchangeIntegrationQueue.QueueDraftEmailRequest(email, firstCaseIncluded, (staffId, userIdentityId));

            await _dbContext.SaveChangesAsync();

            tcs.Complete();

            _logger.Trace($"{nameof(EnqueueReviewEmailDraft)}: Queued for review in {email.Mailbox}, [OpenItemNo={request.OpenItemNo} ({request.ItemEntityId}/{request.ItemTransactionId}/{request.ResultFilePath})]");
        }
    }
}
