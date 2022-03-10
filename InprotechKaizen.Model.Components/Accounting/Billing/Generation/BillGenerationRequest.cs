using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation
{
    public class BillGenerationRequest
    {
        public int ItemEntityId { get; set; }
        public int? ItemTransactionId { get; set; }
        public string OpenItemNo { get; set; }
        public string LoginId { get; set; }
        public string FileName { get; set; }
        public bool IsFinalisedBill { get; set; }
        public bool ShouldMarkBillAsPrinted { get; set; }
        public bool ShouldPrintAsOriginal { get; set; }
        public bool ShouldSuppressPdf { get; set; }
        public bool ShouldNotPrintCopyTo { get; set; }
        public string ResultFilePath { get; set; }
    }
}