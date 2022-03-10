using System;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class SplitWipItemsPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly ISplitWipCommand _splitWipCommand;
        readonly IApplicationAlerts _applicationAlerts;
        readonly ILogger<SplitWipItemsPersistence> _logger;

        public SplitWipItemsPersistence(ISplitWipCommand splitWipCommand, IApplicationAlerts applicationAlerts, ILogger<SplitWipItemsPersistence> logger)
        {
            _splitWipCommand = splitWipCommand;
            _applicationAlerts = applicationAlerts;
            _logger = logger;
        }

        public Stage Stage => Stage.ProcessSplitWip;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));

            var distinctSplitWipRefKeys = (from w in model.AvailableWipItems
                                           where w.SplitWipRefKey != null && w.IsDraft
                                           select (int)w.SplitWipRefKey).Distinct();

            foreach (var splitWipRefKey in distinctSplitWipRefKeys)
            {
                if (result.HasError) continue;

                var wipItemsToSplit = model.AvailableWipItems
                                           .Where(_ => _.SplitWipRefKey == splitWipRefKey)
                                           .ToArray();

                var splitTransactionId = (int?)null;
                foreach (var wipItem in wipItemsToSplit)
                {
                    try
                    {
                        var isLast = wipItem == wipItemsToSplit.Last();
                        var split = await _splitWipCommand.Split(userIdentityId, culture,
                                                                 new SplitWipItem
                                                                 {
                                                                     EntityKey = wipItem.EntityId,
                                                                     TransKey = wipItem.TransactionId,
                                                                     WipSeqKey = wipItem.WipSeqNo,
                                                                     StaffKey = wipItem.StaffId,
                                                                     ProfitCentreKey = wipItem.StaffProfitCentre,
                                                                     ReasonCode = wipItem.SplitWipReasonCode,
                                                                     LocalAmount = wipItem.LocalBilled,
                                                                     ForeignAmount = wipItem.ForeignBilled,
                                                                     IsLastSplit = isLast,
                                                                     NewTransKey = splitTransactionId
                                                                 });

                        splitTransactionId = split.NewTransKey;

                        result.SplitWipItems.Add(new DraftWipDetails
                        {
                            UniqueReferenceId = wipItem.UniqueReferenceId,
                            DraftWipRefId = wipItem.UniqueReferenceId,
                            TransactionId = wipItem.TransactionId = split.NewTransKey.GetValueOrDefault(),
                            WipSeqNo = wipItem.WipSeqNo = split.NewWipSeqKey.GetValueOrDefault()
                        });

                        _logger.Trace($"SplitWipItem added [SplitWipRefKey={splitWipRefKey}/UniqueReferenceId={wipItem.UniqueReferenceId}/NewTransId={splitTransactionId}/NewWipSeq={wipItem.WipSeqNo}]", wipItem);
                    }
                    catch (SqlException e)
                    {
                        if (_applicationAlerts.TryParse(e.Message, out var alerts))
                        {
                            var alert = alerts.First();
                            result.ErrorCode = alert.AlertID;
                            result.ErrorDescription = alert.Message;

                            _logger.Warning($"SplitWipItem alert={result.ErrorCode} [SplitWipRefKey={splitWipRefKey}]", wipItem);
                            break;
                        }

                        throw;
                    }
                }

                if (result.HasError)
                    break;

                ApplyPersistedSplitWipIdsToBillLineWip(model, result, splitWipRefKey);
            }
            
            return !result.HasError;
        }

        void ApplyPersistedSplitWipIdsToBillLineWip(OpenItemModel model, SaveOpenItemResult result, int splitWipRefKey)
        {
            var applied = 0;

            foreach (var wipItem in model.BillLines.SelectMany(_ => _.WipItems))
            {
                if (wipItem.SplitWipRefId != splitWipRefKey) continue;

                var split = result.SplitWipItems
                                  .Single(_ => wipItem.UniqueReferenceId == _.UniqueReferenceId);

                wipItem.TransactionId = split.TransactionId;
                wipItem.WipSeqNo = split.WipSeqNo;
                applied++;
            }

            if (applied > 0)
            {
                _logger.Trace($"{nameof(ApplyPersistedSplitWipIdsToBillLineWip)} # Applied={applied} [SplitWipRefKey={splitWipRefKey}]");
            }
        }
    }
}
