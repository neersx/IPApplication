using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public interface IPostWipCommand
    {
        Task<IEnumerable<WipPosted>> Post(int userIdentityId, string culture, params PostWipParameters[] parameters);
    }

    public class PostWipCommand : IPostWipCommand
    {
        readonly IDbContext _dbContext;
        readonly ILogger<PostWipCommand> _logger;

        public PostWipCommand(IDbContext dbContext, ILogger<PostWipCommand> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<IEnumerable<WipPosted>> Post(int userIdentityId, string culture, params PostWipParameters[] parameters)
        {
            var hasMultipleItemsToPost = parameters.Length > 1;

            int? ItemTransNoModifier(PostWipParameters currentParameter, WipPosted postedWipResult)
            {
                return hasMultipleItemsToPost && postedWipResult != null
                    ? postedWipResult.TransNo /* all transaction in the same post wip call are the same */
                    : currentParameter.ItemTransNo;
            }

            var index = 0;

            var wipPostingResult = new List<WipPosted>();

            foreach (var parameter in parameters)
            {
                var inputParameters = new Parameters
                {
                    {"@pnUserIdentityId", userIdentityId},
                    {"@psCulture", culture},
                    {"@pbCalledFromCentura", false},
                    {"@pnEntityKey", parameter.EntityKey},
                    {"@pdtTransDate", parameter.TransactionDate},
                    {"@pnTransactionType", parameter.TransactionType},
                    {"@pnWIPToNameNo", parameter.NameKey},
                    {"@pnWIPToCaseId", parameter.CaseKey},
                    {"@pnEmployeeNo", parameter.StaffKey},
                    {"@pnAssociateNo", parameter.AssociateKey},
                    {"@psInvoiceNumber", parameter.InvoiceNumber},
                    {"@psVerificationNumber", parameter.VerificationNumber},
                    {"@pnRateNo", parameter.RateNo},
                    {"@psWIPCode", parameter.WipCode},
                    {"@pdtTotalTime", parameter.TotalTime},
                    {"@pnTotalUnits", parameter.TotalUnits},
                    {"@pnUnitsPerHour", parameter.UnitsPerHour},
                    {"@pnChargeOutRate", parameter.ChargeOutRate},
                    {"@pnLocalValue", parameter.LocalValue},
                    {"@pnForeignValue", parameter.ForeignValue},
                    {"@psForeignCurrency", parameter.ForeignCurrency},
                    {"@pnExchangeRate", parameter.ExchangeRate},
                    {"@pnDiscountValue", parameter.DiscountValue},
                    {"@pnForeignDiscount", parameter.ForeignDiscount},
                    {"@pnVariableFeeAmt", parameter.VariableFeeAmount},
                    {"@pnVariableFeeType", parameter.VariableFeeType},
                    {"@psVariableCurrency", parameter.VariableCurrency},
                    {"@pnFeeCriteriaNo", parameter.FeeCriteriaNo},
                    {"@pnFeeUniqueId", parameter.FeeUniqueId},
                    {"@pnQuotationNo", parameter.QuotationNo},
                    {"@pnLocalCost", parameter.LocalCost},
                    {"@pnForeignCost", parameter.ForeignCost},
                    {"@pnCostCalculation1", parameter.CostCalculation1},
                    {"@pnCostCalculation2", parameter.CostCalculation2},
                    {"@pnEnteredQuantity", parameter.EnteredQuantity},
                    {"@pnProductCode", parameter.ProductCode},
                    {"@pbGeneratedInAdvance", parameter.IsGeneratedInAdvance},
                    {"@pnNarrativeNo", parameter.NarrativeKey},
                    {"@psNarrative", parameter.Narrative},
                    {"@psFeeType", parameter.FeeType},
                    {"@pnBaseFeeAmount", parameter.BaseFeeAmount},
                    {"@pnAdditionalFee", parameter.AdditionalFee},
                    {"@psFeeTaxCode", parameter.FeeTaxCode},
                    {"@pnFeeTaxAmount", parameter.FeeTaxAmount},
                    {"@pnAgeOfCase", parameter.AgeOfCase},
                    {"@pnMarginNo", parameter.MarginNo},
                    {"@pbDraftWIP", parameter.IsDraftWip},
                    {"@pnItemTransNo", ItemTransNoModifier(parameter, wipPostingResult.FirstOrDefault())},
                    {"@bIsCreditWIP", parameter.IsCreditWip},
                    {"@pbSeparateMarginFlag", parameter.ShouldSeparateMargin},
                    {"@pnLocalMargin", parameter.MarginValue},
                    {"@pnForeignMargin", parameter.ForeignMargin},
                    {"@pnDiscountForMargin", parameter.DiscountForMargin},
                    {"@pnForeignDiscountForMargin", parameter.ForeignDiscountForMargin},
                    {"@psReasonCode", parameter.ReasonCode},
                    {"@pbReturnWIPKey", parameter.ShouldReturnWipKey},
                    {"@pbBillingDiscountFlag", parameter.IsBillingDiscount},
                    {"@pbSuppressCommit", parameter.ShouldSuppressCommit},
                    {"@pbSuppressPostToGL", parameter.ShouldSuppressPostToGeneralLedger},
                    {"@psProtocolNo", parameter.ProtocolKey},
                    {"@psProtocolDateString", parameter.ProtocolDate},
                    {"@psProfitCentreCode", parameter.ProfitCentreCode},
                    {"@pbIsSplitWip", parameter.IsSplitDebtorWip},
                    {"@pnSplitPercentage", parameter.DebtorSplitPercentage}
                };

                using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.WipManagement.PostWip, inputParameters);

                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    var posted = new WipPosted
                    {
                        TransNo = reader.GetField<int>("TransNo"),
                        WipCode = reader.GetField<string>("WipCode"),
                        WipSeqNo = reader.GetField<short>("WipSeqNo"),
                        DiscountFlag = reader.GetField<decimal>("DiscountFlag") == 1,
                        MarginFlag = reader.GetField<decimal>("MarginFlag") == 1,

                        RefId = parameter.RefId,
                        IsBillingDiscount = parameter.IsBillingDiscount,
                        IsDraft = parameter.IsDraftWip
                    };

                    _logger.Trace($"WIP Posting {index}/{parameters.Length}",
                                  new
                                  {
                                      input = parameter,
                                      result = posted
                                  });

                    wipPostingResult.Add(posted);
                }

                index++;
            }
            
            return wipPostingResult;
        }
    }

    public class PostWipParameters : UnpostedWip
    {
        public int? RefId { get; set; }
    }

    public class WipPosted
    {
        public int? RefId { get; set; }
        public bool IsDraft { get; set; }
        public bool IsBillingDiscount { get; set; }
        public int TransNo { get; set; }
        public string WipCode { get; set; }
        public short WipSeqNo { get; set; }
        public bool DiscountFlag { get; set; }
        public bool MarginFlag { get; set; }
    }
}