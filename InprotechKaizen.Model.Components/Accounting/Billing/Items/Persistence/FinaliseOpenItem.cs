using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class FinaliseOpenItem : IFinaliseDraftBill
    {
        readonly IDraftBillManagementCommands _draftBillManagementCommands;
        readonly ILogger<FinaliseOpenItem> _logger;

        public FinaliseOpenItem(IDraftBillManagementCommands draftBillManagementCommands, ILogger<FinaliseOpenItem> logger)
        {
            _draftBillManagementCommands = draftBillManagementCommands;
            _logger = logger;
        }

        public FinaliseBillStage Stage => FinaliseBillStage.PostOpenItem;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null || model.ItemTransactionId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)} and {nameof(model.ItemTransactionId)} must both have a value.");
            }

            var interim = await _draftBillManagementCommands.Finalise(userIdentityId, culture,
                                                                      (int)model.ItemEntityId,
                                                                      (int)model.ItemTransactionId,
                                                                      model.EnteredOpenItemXml,
                                                                      model.FinalisedItemDate ?? model.ItemDate);

            if (interim.Alerts.Any())
            {
                var alert = interim.Alerts.First();
                result.ErrorCode = alert.AlertID;
                result.ErrorDescription = alert.Message;

                _logger.Warning($"Finalise {model.ItemEntityId}/{model.ItemTransactionId}, alert={result.ErrorCode}/{result.ErrorDescription}");

                return false;
            }

            model.OpenItemNo = interim.DebtorOpenItemNos.Last().OpenItemNo;

            result.DebtorOpenItemNos.AddRange(interim.DebtorOpenItemNos);

            result.ReconciliationErrors.AddRange(interim.ReconciliationErrors);

            _logger.Trace($"Finalised {model.OpenItemNo}, result=", result);

            return true;
        }
    }
}
