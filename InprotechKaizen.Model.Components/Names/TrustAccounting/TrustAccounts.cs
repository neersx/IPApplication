
namespace InprotechKaizen.Model.Components.Names.TrustAccounting
{
    public class TrustAccounts
    {
        public string Id { get; set; }
        public int EntityKey { get; set; }
        public string Entity { get; set; }
        public int BankAccountNameKey { get; set; }
        public int BankAccountSeqKey { get; set; }
        public string BankAccount { get; set; }
        public decimal? LocalBalance { get; set; }
        public decimal? ForeignBalance { get; set; }
        public string LocalCurrency { get; set; }
        public string Currency { get; set; }
    }
}
