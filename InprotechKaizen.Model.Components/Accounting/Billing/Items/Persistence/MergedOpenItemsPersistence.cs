using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class MergedOpenItemsPersistence : INewDraftBill
    {
        readonly IDraftWipManagementCommands _draftWipManagementCommands;
        readonly IDraftBillManagementCommands _draftBillManagementCommands;
        readonly ILogger<MergedOpenItemsPersistence> _logger;

        public MergedOpenItemsPersistence(IDraftWipManagementCommands draftWipManagementCommands,
                                          IDraftBillManagementCommands draftBillManagementCommands,
                                          ILogger<MergedOpenItemsPersistence> logger)
        {
            _draftWipManagementCommands = draftWipManagementCommands;
            _draftBillManagementCommands = draftBillManagementCommands;
            _logger = logger;
        }

        public Stage Stage => Stage.ManageMergedOpenItems;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));

            if (string.IsNullOrWhiteSpace(model.MergedItemKeysInXml))
            {
                return true;
            }

            if (!await ImportMergedOpenItems(userIdentityId, culture, model, result))
            {
                return false;
            }

            return await DeleteUnmergedOpenItems(userIdentityId, culture, model);
        }

        async Task<bool> ImportMergedOpenItems(int userIdentityId, string culture, OpenItemModel model, SaveOpenItemResult result)
        {
            if (model.ItemEntityId == null || model.ItemTransactionId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)} and {nameof(model.ItemTransactionId)} must both have a value.");
            }

            var r = await _draftWipManagementCommands.CopyDraftWip(userIdentityId, culture,
                                                                   new MergeXmlKeys(model.MergedItemKeysInXml),
                                                                   (int)model.ItemEntityId, (int)model.ItemTransactionId);

            if (r.Alerts.Any())
            {
                result.ErrorCode = r.Alerts.First().AlertID;
                result.ErrorDescription = r.Alerts.First().Message;

                _logger.Warning($"{nameof(ImportMergedOpenItems)} alert={result.ErrorCode}/{result.ErrorDescription}");
                
                return false;
            }

            var originalDraftWipItemCount = result.DraftWipItems.Count;
            foreach (var remappedWipItem in r.RemappedWipItems)
            {
                var wip = model.AvailableWipItems.Single(_ => _.EntityId == remappedWipItem.EntityId &&
                                                              _.TransactionId == remappedWipItem.TransactionId &&
                                                              _.WipSeqNo == remappedWipItem.WipSeqNo);

                wip.EntityId = (int)model.ItemEntityId;
                wip.TransactionId = (int)model.ItemTransactionId;
                wip.WipSeqNo = remappedWipItem.NewWipSeqNo;

                if (remappedWipItem.WipSeqNo != remappedWipItem.NewWipSeqNo)
                {
                    result.DraftWipItems.Add(new DraftWipDetails
                    {
                        UniqueReferenceId = wip.UniqueReferenceId,
                        WipSeqNo = wip.WipSeqNo
                    });
                }

                foreach (var billLine in model.BillLines)
                {
                    var modelBillLineWipItem = billLine.WipItems
                                                       .SingleOrDefault(_ => _.DraftWipRefId == wip.UniqueReferenceId &&
                                                                             _.IsDiscount == wip.IsDiscount.GetValueOrDefault() &&
                                                                             _.IsMargin == wip.IsMargin.GetValueOrDefault());

                    if (modelBillLineWipItem == null) continue;

                    modelBillLineWipItem.EntityId = wip.EntityId;
                    modelBillLineWipItem.TransactionId = wip.TransactionId;
                    modelBillLineWipItem.WipSeqNo = wip.WipSeqNo;
                }
            }

            if (result.DraftWipItems.Any())
            {
                _logger.Trace($"{nameof(ImportMergedOpenItems)} # Imported: DraftWipItems={result.DraftWipItems.Count - originalDraftWipItemCount}");
            }

            return true;
        }

        async Task<bool> DeleteUnmergedOpenItems(int userIdentityId, string culture, OpenItemModel model)
        {
            var keys = new MergeXmlKeys(model.MergedItemKeysInXml);

            await _draftBillManagementCommands.Delete(userIdentityId, culture, keys);
            
            _logger.Trace($"{nameof(DeleteUnmergedOpenItems)} Deleted", keys);

            return true;
        }
    }
}
