using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class DraftWipDetailPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IIndex<TypeOfDraftWipPersistence, ISaveOpenItemDraftWip> _draftWipPersistenceHandlers;
        readonly ILogger<DraftWipDetailPersistence> _logger;

        public DraftWipDetailPersistence(IIndex<TypeOfDraftWipPersistence, ISaveOpenItemDraftWip> draftWipPersistenceHandlers, ILogger<DraftWipDetailPersistence> logger)
        {
            _draftWipPersistenceHandlers = draftWipPersistenceHandlers;
            _logger = logger;
        }

        public Stage Stage => Stage.SaveDraftOrActiveWip;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));
            
            var draftWipPersistenceHandler = GetDraftWipPersistenceHandler(settings);

            var draftWipItems = GetDraftWipItems(model);

            var handlerResult = await draftWipPersistenceHandler.Save(userIdentityId, culture, draftWipItems, model.ItemTransactionId, (ItemType) model.ItemType, result.RequestId);

            if (handlerResult.HasError)
            {
                result.ErrorCode = handlerResult.ErrorCode;
                result.ErrorDescription = handlerResult.ErrorDescription;
                
                _logger.Warning($"{draftWipPersistenceHandler.GetType().Name}.Save alert={result.ErrorCode}/{result.ErrorDescription}");

                return false;
            }

            ApplyPersistedResults(model, result, handlerResult.PersistedWipDetails);

            return true;
        }

        void ApplyPersistedResults(OpenItemModel model, SaveOpenItemResult result, IEnumerable<DraftWipDetails> persistedWipDetails)
        {
            var originalCount = result.DraftWipItems.Count;

            foreach (var persisted in persistedWipDetails)
            {
                var modelWipItem = model.AvailableWipItems
                                        .Single(_ => _.IsDraft &&
                                                     _.IsDiscount.GetValueOrDefault() == persisted.IsDiscount &&
                                                     _.IsMargin.GetValueOrDefault() == persisted.IsMargin &&
                                                     _.DraftWipRefId == persisted.DraftWipRefId);

                modelWipItem.WipSeqNo = persisted.WipSeqNo;
                modelWipItem.TransactionId = persisted.TransactionId;

                foreach (var billLine in model.BillLines)
                {
                    var modelBillLineWipItem = billLine.WipItems
                                                       .SingleOrDefault(_ =>
                                                                            _.IsDiscount == persisted.IsDiscount &&
                                                                            _.IsMargin == persisted.IsMargin &&
                                                                            _.DraftWipRefId == persisted.DraftWipRefId);

                    if (modelBillLineWipItem == null) continue;

                    modelBillLineWipItem.WipSeqNo = persisted.WipSeqNo;
                    modelBillLineWipItem.TransactionId = persisted.TransactionId;
                }

                result.DraftWipItems.Add(persisted);
            }

            _logger.Trace($"{nameof(ApplyPersistedResults)} # Added: DraftWipItems={result.DraftWipItems.Count - originalCount}");
        }

        IEnumerable<DraftWip> GetDraftWipItems(OpenItemModel model)
        {
            return (from wipItem in model.AvailableWipItems
                    where wipItem.DraftWipData != null
                    let draftWip = SynchroniseCostSigns(wipItem.DraftWipData)
                    select draftWip)
                .ToArray();
        }

        ISaveOpenItemDraftWip GetDraftWipPersistenceHandler(BillingSiteSettings settings)
        {
            var draftWipPersistenceHandler = settings.WIPSplitMultiDebtor switch
            {
                true => _draftWipPersistenceHandlers[TypeOfDraftWipPersistence.WipSplitMultiDebtor],
                _ => _draftWipPersistenceHandlers[TypeOfDraftWipPersistence.Default]
            };

            return draftWipPersistenceHandler;
        }

        DraftWip SynchroniseCostSigns(DraftWip wip)
        {
            var logBuilder = new StringBuilder();
            var isPositive = (wip.LocalValue ?? 0) > 0;

            if (SynchroniseSign(wip.LocalCost, isPositive, out var synchronisedLocalCost))
            {
                logBuilder.AppendFormat("/LocalCost {0} -> {1}", wip.LocalCost, synchronisedLocalCost);
                wip.LocalCost = synchronisedLocalCost;
            }

            if (SynchroniseSign(wip.ForeignCost, isPositive, out var synchronisedForeignCost))
            {
                logBuilder.AppendFormat("/ForeignCost {0} -> {1}", wip.ForeignCost, synchronisedForeignCost);
                wip.ForeignCost = synchronisedForeignCost;
            }

            if (SynchroniseSign(wip.CostCalculation1, isPositive, out var synchronisedCostCalculation1))
            {
                logBuilder.AppendFormat("/CostCalculation1 {0} -> {1}", wip.CostCalculation1, synchronisedCostCalculation1);
                wip.CostCalculation1 = synchronisedCostCalculation1;
            }

            if (SynchroniseSign(wip.CostCalculation2, isPositive, out var synchronisedCostCalculation2))
            {
                logBuilder.AppendFormat("/CostCalculation2 {0} -> {1}", wip.CostCalculation2, synchronisedCostCalculation2);
                wip.CostCalculation2 = synchronisedCostCalculation2;
            }

            var log = logBuilder.ToString();
            if (!string.IsNullOrWhiteSpace(log))
            {
                _logger.Trace($"{nameof(SynchroniseCostSigns)} Synced={log.TrimStart('/')} [DraftWipRefId={wip.DraftWipRefId}]");
            }

            return wip;
        }

        static bool SynchroniseSign(decimal? value, bool isPositive, out decimal? synchronisedValue)
        {
            synchronisedValue = value == null
                ? null
                : Math.Abs(value.Value) * (isPositive ? 1 : -1);
            
            return synchronisedValue != value;
        } 
    }
}
