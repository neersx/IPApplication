using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public interface IOpenItemDetailPersistence : IContextualLogger
    {
        Stage Stage { get; }
    
        Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result);
    }

    public interface INewDraftBill : IOpenItemDetailPersistence
    {
        
    }

    public interface IUpdateDraftBill : IOpenItemDetailPersistence
    {
    }

    public interface IFinaliseDraftBill
    { 
        FinaliseBillStage Stage { get; }
        
        void SetLogContext(Guid contextId);

        Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result);
    }

    public enum Stage
    {
        Preprocess,
        SaveOpenItem,
        ManageMergedOpenItems,
        SaveOpenItemTax,
        SaveBillCredits,
        SaveOpenItemCopiesTo,
        ProcessSplitWip,
        SaveDraftOrActiveWip,
        SaveBillLines,
        SaveOpenItemXml,
        SaveBilledItems,
        PostDebtorHistoryForCreditNote,
        GenerateChangeAlert
    }

    public enum FinaliseBillStage
    {
        PostOpenItem,
        GenerateBillThenSendForReview
    }

    public class SaveOpenItemResult
    {
        public SaveOpenItemResult()
        {

        }

        public SaveOpenItemResult(Guid requestId)
        {
            RequestId = requestId;
        }

        public SaveOpenItemResult(string errorCode, string errorDescription)
        {
            ErrorCode = errorCode;
            ErrorDescription = errorDescription;
        }

        public Guid RequestId { get; set; }
        public string ErrorCode { get; set; }
        public string ErrorDescription { get; set; }
        public int? ContentId { get; set; }
        public int? TransactionId { get; set; }
        public DateTime? LogDateTimeStamp { get; set; } // TRANSACTIONHEADER.LOGDATETIMESTAMP
        public ICollection<DebtorOpenItemNo> DebtorOpenItemNos { get; set; } = new List<DebtorOpenItemNo>();
        public ICollection<DraftWipDetails> DraftWipItems { get; set; } = new List<DraftWipDetails>();
        public ICollection<DraftWipDetails> SplitWipItems { get; set; } = new List<DraftWipDetails>();
        public ICollection<string> ReconciliationErrors { get; set; } = new List<string>();
        public string ErrorBillSaveAsPdf { get; set; }
        public bool HasError => !string.IsNullOrWhiteSpace(ErrorCode);
    }
}