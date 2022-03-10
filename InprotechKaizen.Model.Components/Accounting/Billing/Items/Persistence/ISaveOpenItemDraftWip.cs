using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public interface ISaveOpenItemDraftWip
    {
        Task<SaveOpenItemDraftWipResult> Save(int userIdentityId, string culture,
                                              IEnumerable<DraftWip> draftWipItemsToSave,
                                              int? openItemTransactionId, ItemType openItemItemType, Guid requestId);
    }

    public class SaveOpenItemDraftWipResult
    {
        public ICollection<DraftWipDetails> PersistedWipDetails { get; }

        public string ErrorCode { get; set; }

        public string ErrorDescription { get; set; }

        public bool HasError => !string.IsNullOrWhiteSpace(ErrorCode);

        public SaveOpenItemDraftWipResult()
        {
            PersistedWipDetails = new List<DraftWipDetails>();
        }

        public SaveOpenItemDraftWipResult(IEnumerable<DraftWipDetails> resultDetails)
        {
            PersistedWipDetails = new List<DraftWipDetails>(resultDetails);
        }

        public SaveOpenItemDraftWipResult(string errorCode, string errorDescription)
        {
            PersistedWipDetails = Array.Empty<DraftWipDetails>();
            ErrorCode = errorCode;
            ErrorDescription = errorDescription;
        }
    }

    public enum TypeOfDraftWipPersistence
    {
        Default,
        WipSplitMultiDebtor
    }

    internal class SaveOpenItemDraftWipLogHelper
    {
        internal static PostWipParameters Log(ILogger logger, DraftWip draftWip, PostWipParameters parameter, int index, Guid requestId, bool withSideEffects = false)
        {
            var logBuilder = new StringBuilder();
            var logHeaderBuilder = new StringBuilder();
            var logFooterBuilder = new StringBuilder();

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.LocalValue), draftWip.LocalValue, parameter.LocalValue))
                draftWip.LocalValue = parameter.LocalValue;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.LocalCost), draftWip.LocalCost, parameter.LocalCost))
                draftWip.LocalCost = parameter.LocalCost;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.Margin), draftWip.Margin, parameter.MarginValue))
                draftWip.Margin = parameter.MarginValue;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.CostCalculation1), draftWip.CostCalculation1, parameter.CostCalculation1))
                draftWip.CostCalculation1 = parameter.CostCalculation1;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.CostCalculation2), draftWip.CostCalculation2, parameter.CostCalculation2))
                draftWip.CostCalculation2 = parameter.CostCalculation2;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.ForeignValue), draftWip.ForeignValue, parameter.ForeignValue))
                draftWip.ForeignValue = parameter.ForeignValue;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.ForeignCost), draftWip.ForeignCost, parameter.ForeignCost))
                draftWip.ForeignCost = parameter.ForeignCost;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.ForeignMargin), draftWip.ForeignMargin, parameter.ForeignMargin))
                draftWip.ForeignMargin = parameter.ForeignMargin;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.LocalDiscount), draftWip.LocalDiscount, parameter.DiscountValue))
                draftWip.LocalDiscount = parameter.DiscountValue;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.LocalDiscountForMargin), draftWip.LocalDiscountForMargin, parameter.DiscountForMargin))
                draftWip.LocalDiscountForMargin = parameter.DiscountForMargin;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.ForeignDiscount), draftWip.ForeignDiscount, parameter.ForeignDiscount))
                draftWip.ForeignDiscount = parameter.ForeignDiscount;

            if (withSideEffects && LogIfNotEqual(logBuilder, nameof(draftWip.ForeignDiscountForMargin), draftWip.ForeignDiscountForMargin, parameter.ForeignDiscountForMargin))
                draftWip.ForeignDiscountForMargin = parameter.ForeignDiscountForMargin;
            
            logFooterBuilder.AppendFormat("[DraftWipRefId={0}", draftWip.DraftWipRefId);

            if (draftWip.SplitGroupKey != null)
            {
                logFooterBuilder.AppendFormat("SplitGroupKey={0}", draftWip.SplitGroupKey);
            }

            if (!string.IsNullOrWhiteSpace(draftWip.IsGeneratedFromTaxCode))
            {
                logHeaderBuilder.AppendFormat("PostStampFeeWip #{0}", index);
                logFooterBuilder.AppendFormat("GeneratedFromStampFee={0}", draftWip.IsGeneratedFromTaxCode);
            }
            else
            {
                logHeaderBuilder.AppendFormat("PostWip #{0}", index);
            }

            logFooterBuilder.Append("]");
            
            var log = logBuilder.ToString();
            if (!string.IsNullOrWhiteSpace(log))
            {
                logHeaderBuilder.Append(" ReverseSigns");
            }

            if (draftWip.IsCreditWip == true)
            {
                logHeaderBuilder.Append(" Credit");
            }

            if (draftWip.IsAdvanceBill == true)
            {
                logHeaderBuilder.Append(" AdvancedBill");
            }

            if (!parameter.ShouldSuppressPostToGeneralLedger)
            {
                logHeaderBuilder.Append(" PostToGL");
            }

            logger.Trace($"{logHeaderBuilder}={log.TrimStart('/')} {logFooterBuilder}");

            return parameter;
        }

        static bool LogIfNotEqual<T>(StringBuilder logBuilder, string fieldName, T draftWipValue, T parameterValue)
        {
            if (!EqualityComparer<T>.Default.Equals(draftWipValue, parameterValue))
            {
                logBuilder.AppendFormat("/{0} {1} -> {2}", fieldName, draftWipValue, parameterValue);
                return true;
            }

            return false;
        }
    }
}