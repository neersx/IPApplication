using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class SaveDraftWip : ISaveOpenItemDraftWip
    {
        readonly IPostWipCommand _postWipCommand;
        readonly IApplicationAlerts _applicationAlerts;
        readonly ILogger<SaveDraftWip> _logger;

        public SaveDraftWip(IPostWipCommand postWipCommand, IApplicationAlerts applicationAlerts, ILogger<SaveDraftWip> logger)
        {
            _postWipCommand = postWipCommand;
            _applicationAlerts = applicationAlerts;
            _logger = logger;
        }

        public async Task<SaveOpenItemDraftWipResult> Save(int userIdentityId, string culture,
                                                           IEnumerable<DraftWip> draftWipItemsToSave,
                                                           int? openItemTransactionId, ItemType openItemItemType, Guid requestId)
        {
            try
            {
                _logger.SetContext(requestId);

                var parameters = (from draftWip in draftWipItemsToSave
                                  let isForeign = !string.IsNullOrWhiteSpace(draftWip.ForeignCurrencyCode)
                                  let isAdvancedBill = draftWip.IsAdvanceBill.GetValueOrDefault()
                                  select new
                                  {
                                      Key = draftWip,
                                      Value =
                                          new PostWipParameters
                                          {
                                              RefId = draftWip.DraftWipRefId,
                                              EntityKey = (int)draftWip.EntityId,
                                              TransactionDate = (DateTime)draftWip.EntryDate,
                                              TransactionType = (int)openItemItemType,
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

                                              LocalValue = isAdvancedBill
                                                  ? draftWip.LocalValue * -1
                                                  : draftWip.LocalValue,
                                              LocalCost = isAdvancedBill
                                                  ? draftWip.LocalCost * -1
                                                  : draftWip.LocalCost,
                                              CostCalculation1 = isAdvancedBill
                                                  ? draftWip.CostCalculation1 * -1
                                                  : draftWip.CostCalculation1,
                                              CostCalculation2 = isAdvancedBill
                                                  ? draftWip.CostCalculation2 * -1
                                                  : draftWip.CostCalculation2,
                                              MarginValue = isAdvancedBill
                                                  ? draftWip.Margin * -1
                                                  : draftWip.Margin,

                                              DiscountValue = isAdvancedBill
                                                  ? draftWip.LocalDiscount * -1
                                                  : draftWip.LocalDiscount,
                                              DiscountForMargin = isAdvancedBill
                                                  ? draftWip.LocalDiscountForMargin * -1
                                                  : draftWip.LocalDiscountForMargin,

                                              ForeignCurrency = draftWip.ForeignCurrencyCode,
                                              ExchangeRate = !isForeign ? null : draftWip.ExchangeRate,
                                              ForeignValue = !isForeign
                                                  ? null
                                                  : isAdvancedBill
                                                      ? draftWip.ForeignValue * -1
                                                      : draftWip.ForeignValue,
                                              ForeignCost = !isForeign
                                                  ? null
                                                  : isAdvancedBill
                                                      ? draftWip.ForeignCost * -1
                                                      : draftWip.ForeignCost,
                                              ForeignMargin = !isForeign
                                                  ? null
                                                  : isAdvancedBill
                                                      ? draftWip.ForeignMargin * -1
                                                      : draftWip.ForeignMargin,

                                              ForeignDiscount = !isForeign
                                                  ? null
                                                  : isAdvancedBill
                                                      ? draftWip.ForeignDiscount * -1
                                                      : draftWip.ForeignDiscount,
                                              ForeignDiscountForMargin = !isForeign
                                                  ? null
                                                  : isAdvancedBill
                                                      ? draftWip.ForeignDiscountForMargin * -1
                                                      : draftWip.ForeignDiscountForMargin,

                                              EnteredQuantity = draftWip.IsWipItem.GetValueOrDefault() == false
                                                  ? draftWip.EnteredChargeQuantity
                                                  : draftWip.EnteredQuantity,
                                              ProductCode = draftWip.ProductId,
                                              NarrativeKey = draftWip.NarrativeId,
                                              Narrative = draftWip.Narrative,
                                              MarginNo = draftWip.MarginNo,
                                              ShouldReturnWipKey = true,
                                              ShouldSuppressCommit = true,
                                              ShouldSuppressPostToGeneralLedger = true,
                                              IsDraftWip = true,

                                              ItemTransNo = openItemTransactionId,
                                              IsCreditWip = draftWip.IsCreditWip.GetValueOrDefault(),
                                              IsSeparateMargin = draftWip.IsSeparateMargin.GetValueOrDefault(),
                                              IsBillingDiscount = draftWip.IsBillingDiscount,
                                              IsDiscount = draftWip.IsDiscount,
                                              ProfitCentreCode = draftWip.ProfitCentreCode,
                                              IsSplitDebtorWip = draftWip.IsSplitDebtorWip,
                                              DebtorSplitPercentage = draftWip.DebtorSplitPercentage,
                                              IsGeneratedInAdvance = isAdvancedBill,
                                              FeeType = draftWip.IsFeeType == true ? draftWip.FeeType : null,
                                              BaseFeeAmount = draftWip.BasicAmount,
                                              AdditionalFee = draftWip.ExtendedAmount,
                                              AgeOfCase = draftWip.Cycle,
                                              FeeTaxCode = draftWip.TaxCode,
                                              FeeTaxAmount = draftWip.TaxAmount
                                          }
                                  }).ToDictionary(k => k.Key, v => v.Value);

                var postWipParameters = ReverseSignForAdvancedBillDraftWip(parameters, requestId).ToArray();

                var result = (await _postWipCommand.Post(userIdentityId, culture, postWipParameters)).ToArray();

                _logger.Trace($"SaveDraftWip # Posted={result.Count()}");

                return new SaveOpenItemDraftWipResult(
                                                      result.Select(p => new DraftWipDetails
                                                      {
                                                          DraftWipRefId = (int)p.RefId,
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

        IEnumerable<PostWipParameters> ReverseSignForAdvancedBillDraftWip(Dictionary<DraftWip, PostWipParameters> parameters, Guid requestId)
        {
            var index = 0;
            foreach (var p in parameters)
            {
                var draftWip = p.Key;
                var parameter = p.Value;
                
                /*
                 * TO REVIEW: this logic here creates side-effect refer to SaveDraftWip.cs from Inprotech repo, unsure if it was intentional
                 * 
                 * */

                SaveOpenItemDraftWipLogHelper.Log(_logger, draftWip, parameter, index++, requestId, withSideEffects: true);
                
                yield return parameter;
            }
        }
    }
}