namespace InprotechKaizen.Model.Components.Accounting.Billing.Debtors
{
    public class DebtorCopiesTo
    {
        public int DebtorNameId { get; set; }
        public int CopyToNameId { get; set; }
        public string CopyToName { get; set; }
        public int? ContactNameId { get; set; }
        public string ContactName { get; set; }
        public int? AddressId { get; set; }
        public string Address { get; set; }
        public int? AddressChangeReasonId { get; set; }
        public bool IsCopyToNameChanged { get; set; }
        public bool IsNewCopyToName { get; set; }
        public bool IsDeletedCopyToName { get; set; }
        public bool HasAddressChanged { get; set; }
        public bool HasAttentionChanged { get; set; }
    }
}