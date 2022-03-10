using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Notifications.Validation;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class SaveDraftWipAsPostedWip : ISaveOpenItemDraftWip
    {
        readonly IPostWipCommand _postWipCommand;
        readonly IApplicationAlerts _applicationAlerts;
        readonly ILogger<SaveDraftWipAsPostedWip> _logger;

        public SaveDraftWipAsPostedWip(IPostWipCommand postWipCommand, IApplicationAlerts applicationAlerts, ILogger<SaveDraftWipAsPostedWip> logger)
        {
            _postWipCommand = postWipCommand;
            _applicationAlerts = applicationAlerts;
            _logger = logger;
        }

        public async Task<SaveOpenItemDraftWipResult> Save(int userIdentityId, string culture,
                                                           IEnumerable<DraftWip> draftWipItemsToSave, int? openItemTransactionId, ItemType openItemItemType, Guid requestId)
        {
            if (draftWipItemsToSave == null) throw new ArgumentNullException(nameof(draftWipItemsToSave));

            _logger.SetContext(requestId);

            var allDraftWipItems = draftWipItemsToSave.ToArray();
            var stampFeesItems = allDraftWipItems.Where(dwi => !string.IsNullOrEmpty(dwi.IsGeneratedFromTaxCode)).ToArray();
            var draftWipItems = allDraftWipItems.Except(stampFeesItems).ToArray();

            var result = new SaveOpenItemDraftWipResult();

            if (!await PostStampFeeWip(userIdentityId, culture, stampFeesItems, openItemTransactionId, (int)openItemItemType, result, requestId))
            {
                return result;
            }

            foreach (var split in draftWipItems.GroupBy(_ => _.SplitGroupKey))
            {
                if (!await PostWip(userIdentityId, culture, split.ToArray(), result, requestId))
                {
                    break;
                }
            }

            return result;
        }

        async Task<bool> PostStampFeeWip(int userIdentityId, string culture,
                                         DraftWip[] draftWipItemsToSave,
                                         int? openItemTransactionId, int openItemItemType,
                                         SaveOpenItemDraftWipResult result,
                                         Guid requestId)
        {
            var index = 0;
            foreach (var draftWip in draftWipItemsToSave)
            {
                var r = await PostWipItem(userIdentityId, culture,
                                          openItemTransactionId, openItemItemType, draftWip,
                                          StampFeeDraftWipSignModifierIndicator,
                                          true, /* stamp fees are draft wip items */
                                          false, false,
                                          index, requestId);

                if (r.HasError)
                {
                    result.ErrorCode = r.ErrorCode;
                    result.ErrorDescription = r.ErrorDescription;
                    
                    _logger.Warning($"PostStampFeeWip alert={result.ErrorCode} [{draftWip.DraftWipRefId}/{draftWip.IsGeneratedFromTaxCode}]");
                    break;
                }

                result.PersistedWipDetails.AddRange(r.PersistedWipDetails);

                index++;
            }

            return !result.HasError;
        }

        async Task<bool> PostWip(int userIdentityId, string culture, DraftWip[] draftWipItemsToSave, SaveOpenItemDraftWipResult result, Guid requestId)
        {
            var transactionIdForGroup = (int?)null;
            var index = 0;
            foreach (var draftWip in draftWipItemsToSave)
            {
                var isLast = draftWipItemsToSave.Last() == draftWip;
                var r1 = await PostWipItem(userIdentityId, culture,
                                           transactionIdForGroup, (int)TransactionType.WipRecording, draftWip,
                                           CreditWipDraftWipSignModifierIndicator,
                                           false, /* actual wip items */
                                           true, isLast,
                                           index, requestId);
                if (r1.HasError)
                {
                    result.ErrorCode = r1.ErrorCode;
                    result.ErrorDescription = r1.ErrorDescription;

                    _logger.Warning($"PostWip #{index} alert={result.ErrorCode} [{draftWip.EntityId}/{transactionIdForGroup}/{draftWip.WipSequenceNo}]");
                    break;
                }

                transactionIdForGroup ??= r1.PersistedWipDetails.First().TransactionId;
                result.PersistedWipDetails.AddRange(r1.PersistedWipDetails);

                if (draftWip.IsAdvanceBill == true)
                {
                    var creditWip = (DraftWip)draftWip.Clone();
                    creditWip.IsAdvanceBill = null; /* matching credit should not be marked GeneratedInAdvanced */

                    var r2 = await PostWipItem(userIdentityId, culture,
                                               transactionIdForGroup, (int)TransactionType.WipRecording, creditWip,
                                               MatchingCreditWipDraftWipSignModifierIndicator,
                                               false, /* actual wip items */
                                               true, isLast, 
                                               index, requestId);

                    if (r2.HasError)
                    {
                        result.ErrorCode = r2.ErrorCode;
                        result.ErrorDescription = r2.ErrorDescription;
                    
                        _logger.Warning($"PostWip #{index} AdvancedBill alert={result.ErrorCode} [{draftWip.EntityId}/{transactionIdForGroup}/{draftWip.WipSequenceNo}]");
                        break;
                    }

                    result.PersistedWipDetails.AddRange(r2.PersistedWipDetails);
                }

                index++;
            }

            return !result.HasError;
        }

        async Task<SaveOpenItemDraftWipResult> PostWipItem(int userIdentityId, string culture,
                                                           int? openItemTransactionId, int openItemItemType,
                                                           DraftWip draftWip,
                                                           Func<DraftWip, bool> signModifierIndicatorFunc,
                                                           bool asDraftWip,
                                                           bool shouldPostToGeneralLedgerForLastInGroup,
                                                           bool isLast,
                                                           int index,
                                                           Guid requestId)
        {
            try
            {
                var isForeign = !string.IsNullOrWhiteSpace(draftWip.ForeignCurrencyCode);
                var shouldReverseSign = signModifierIndicatorFunc(draftWip);

                var parameters = new PostWipParameters
                {
                    RefId = draftWip.DraftWipRefId,
                    EntityKey = (int)draftWip.EntityId,
                    TransactionDate = (DateTime)draftWip.EntryDate,
                    TransactionType = openItemItemType,
                    NameKey = draftWip.NameId,
                    CaseKey = draftWip.CaseId,
                    StaffKey = draftWip.StaffId,
                    AssociateKey = draftWip.AssociateNameId,
                    InvoiceNumber = draftWip.InvoiceNumber,
                    VerificationNumber = draftWip.VerificationCode,
                    RateNo = draftWip.RateId,
                    WipCode = draftWip.WipCode ?? draftWip.ActivityId,
                    TotalTime = draftWip.TotalTimeInDateTime(),
                    TotalUnits = draftWip.TotalUnits,
                    UnitsPerHour = draftWip.UnitsPerHour,
                    ChargeOutRate = draftWip.ChargeOutRate,

                    LocalValue = shouldReverseSign
                        ? draftWip.LocalValue * -1
                        : draftWip.LocalValue,
                    LocalCost = shouldReverseSign
                        ? draftWip.LocalCost * -1
                        : draftWip.LocalCost,
                    CostCalculation1 = shouldReverseSign
                        ? draftWip.CostCalculation1 * -1
                        : draftWip.CostCalculation1,
                    CostCalculation2 = shouldReverseSign
                        ? draftWip.CostCalculation2 * -1
                        : draftWip.CostCalculation2,
                    MarginValue = shouldReverseSign
                        ? draftWip.Margin * -1
                        : draftWip.Margin,

                    DiscountValue = draftWip.LocalDiscount,
                    DiscountForMargin = draftWip.LocalDiscountForMargin,

                    ForeignCurrency = draftWip.ForeignCurrencyCode,
                    ExchangeRate = !isForeign ? null : draftWip.ExchangeRate,
                    ForeignValue = !isForeign
                        ? null
                        : shouldReverseSign
                            ? draftWip.ForeignValue * -1
                            : draftWip.ForeignValue,
                    ForeignCost = !isForeign
                        ? null
                        : shouldReverseSign
                            ? draftWip.ForeignCost * -1
                            : draftWip.ForeignCost,
                    ForeignMargin = !isForeign
                        ? null
                        : shouldReverseSign
                            ? draftWip.ForeignMargin * -1
                            : draftWip.ForeignMargin,

                    ForeignDiscount = !isForeign ? null : draftWip.ForeignDiscount,
                    ForeignDiscountForMargin = !isForeign ? null : draftWip.ForeignDiscountForMargin,

                    EnteredQuantity = draftWip.IsWipItem.GetValueOrDefault() == false
                        ? draftWip.EnteredChargeQuantity
                        : draftWip.EnteredQuantity,
                    ProductCode = draftWip.ProductId,
                    NarrativeKey = draftWip.NarrativeId,
                    Narrative = draftWip.Narrative,
                    MarginNo = draftWip.MarginNo,
                    ShouldReturnWipKey = true,
                    ShouldSuppressCommit = true,
                    ShouldSuppressPostToGeneralLedger = !(shouldPostToGeneralLedgerForLastInGroup && isLast),
                    IsDraftWip = asDraftWip,

                    ItemTransNo = openItemTransactionId,
                    IsCreditWip = draftWip.IsCreditWip.GetValueOrDefault(),
                    IsSeparateMargin = draftWip.IsSeparateMargin.GetValueOrDefault(),
                    IsBillingDiscount = draftWip.IsBillingDiscount,
                    IsDiscount = draftWip.IsDiscount,
                    ProfitCentreCode = draftWip.ProfitCentreCode,
                    IsSplitDebtorWip = draftWip.IsSplitDebtorWip,
                    DebtorSplitPercentage = draftWip.DebtorSplitPercentage,
                    IsGeneratedInAdvance = draftWip.IsAdvanceBill,
                    FeeType = draftWip.IsFeeType != true ? draftWip.FeeType : null,
                    BaseFeeAmount = draftWip.BasicAmount,
                    AdditionalFee = draftWip.ExtendedAmount,
                    AgeOfCase = draftWip.Cycle,
                    FeeTaxCode = draftWip.TaxCode,
                    FeeTaxAmount = draftWip.TaxAmount
                };

                SaveOpenItemDraftWipLogHelper.Log(_logger, draftWip, parameters, index, requestId);

                var result = await _postWipCommand.Post(userIdentityId, culture, parameters);

                return new SaveOpenItemDraftWipResult(
                                                      result.Select(p => new DraftWipDetails
                                                      {
                                                          DraftWipRefId = (int) p.RefId,
                                                          UniqueReferenceId = p.RefId,
                                                          TransactionId = p.TransNo,
                                                          WipCode = p.WipCode,
                                                          WipSeqNo = p.WipSeqNo,
                                                          IsDiscount = p.DiscountFlag,
                                                          IsMargin = p.MarginFlag,
                                                          IsBillingDiscount = p.IsBillingDiscount,
                                                          IsDraft = p.IsDraft
                                                      }));
            }
            catch (SqlException e)
            {
                if (_applicationAlerts.TryParse(e.Message, out var alerts))
                {
                    var alert = alerts.First();
                    return new SaveOpenItemDraftWipResult(alert.AlertID, alert.Message);
                }

                throw;
            }
        }
        
        static bool StampFeeDraftWipSignModifierIndicator(DraftWip wip)
        {
            return false;
        }

        static bool CreditWipDraftWipSignModifierIndicator(DraftWip wip)
        {
            return wip.IsCreditWip == true;
        }

        static bool MatchingCreditWipDraftWipSignModifierIndicator(DraftWip wip)
        {
            return true;
        }
    }
}
