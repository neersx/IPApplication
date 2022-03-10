namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class DraftWipDetails
    {
        public int DraftWipRefId { get; set; }
        public int TransactionId { get; set; }
        public string WipCode { get; set; }
        public short WipSeqNo { get; set; }
        public bool IsDiscount { get; set; }
        public bool IsMargin { get; set; }
        public bool IsBillingDiscount { get; set; }
        public int? UniqueReferenceId { get; set; }
        public bool IsDraft { get; set; }
    }
}