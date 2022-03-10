using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class GenerateBillThenSendForReview : IFinaliseDraftBill
    {
        readonly ILogger<GenerateBillThenSendForReview> _logger;
        readonly IBillProductionJobDispatcher _billProductionJobDispatcher;

        public GenerateBillThenSendForReview(ILogger<GenerateBillThenSendForReview> logger,
                                             IBillProductionJobDispatcher billProductionJobDispatcher)
        {
            _logger = logger;
            _billProductionJobDispatcher = billProductionJobDispatcher;
        }

        public FinaliseBillStage Stage => FinaliseBillStage.GenerateBillThenSendForReview;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (result == null) throw new ArgumentNullException(nameof(result));

            if (model.ItemEntityId == null || model.ItemTransactionId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)} and {nameof(model.ItemTransactionId)} must both have a value.");
            }

            if (result.HasError) return false;
            
            if (settings.Options[AdditionalBillingOptions.SendFinalisedBillToReviewer] is true && !settings.CanReviewBillInEmailDraft)
            {
                throw new NotSupportedException("The system has not been configured to review invoice in billing.");
            }

            var trackingDetails = (BillGenerationTracking) settings.Options[AdditionalBillingOptions.BillGenerationTracking];

            var requests = (from d in result.DebtorOpenItemNos
                                         select new BillGenerationRequest
                                         {
                                             ItemEntityId = (int)model.ItemEntityId,
                                             ItemTransactionId = (int)model.ItemTransactionId,
                                             OpenItemNo = d.OpenItemNo,
                                             ShouldPrintAsOriginal = true
                                         }).ToArray();

            if (!requests.Any())
            {
                requests = new[]
                {
                    new BillGenerationRequest
                    {
                        ItemEntityId = (int)model.ItemEntityId,
                        ItemTransactionId = (int)model.ItemTransactionId,
                        OpenItemNo = model.OpenItemNo,
                        ShouldPrintAsOriginal = true
                    }
                };
            }

            await _billProductionJobDispatcher.Dispatch(userIdentityId, culture, trackingDetails, 
                                                        BillProductionType.ProductionDuringFinalisePhase, settings.Options, requests);
         
            return true;
        }
    }
}
