using Inprotech.Web.Names.Details;
using Inprotech.Web.Picklists;
using Newtonsoft.Json;

namespace Inprotech.Web.Names.Maintenance.Models
{
    public class SupplierDetailsSaveModel
    {
        public string SupplierType { get; set; }
        public string PurchaseDescription { get; set; }
        public CodeDescPair PurchaseCurrency { get; set; }
        public CodeDescPair ExchangeRate { get; set; }
        public string DefaultTaxCode { get; set; }
        public string TaxTreatmentCode { get; set; }
        public string PaymentTermNo { get; set; }
        public CodeDescPair ProfitCentre { get; set; }
        public CodeDescPair LedgerAcc { get; set; }
        public CodeDescPair WipDisbursement { get; set; }
        public Name SendToAttentionName { get; set; }
        public Name SendToName { get; set; }
        public AddressPicklistItem SendToAddress { get; set; }
        public string Instruction { get; set; }
        public string WithPayee { get; set; }
        public string PaymentMethod { get; set; }
        public string IntoBankAccountCode { get; set; }
        public string RestrictionKey { get; set; }
        public string OldRestrictionKey { get; set; }
        public string ReasonCode { get; set; }
        public Name SupplierName { get; set; }
        public AddressPicklistItem SupplierNameAddress { get; set; }
        public Name SupplierMainContact { get; set; }
        public Name OldSendToAttentionName { get; set; }
        public Name OldSendToName { get; set; }
        public AddressPicklistItem OldSendToAddress { get; set; }
        public bool HasOutstandingPurchases { get; set; }
        public bool UpdateOutstandingPurchases { get; set; }

        [JsonIgnore]
        public bool HasChangedSendToName => OldSendToName?.Key != SendToName?.Key;
        [JsonIgnore]
        public bool HasChangedSendToAddress => OldSendToAddress?.Id != SendToAddress?.Id;
        [JsonIgnore]
        public bool HasChangedSendToAttentionName => OldSendToAttentionName?.Key != SendToAttentionName?.Key;
        [JsonIgnore]
        public bool IsNotDefaultSendToName => SupplierName?.Key != SendToName?.Key;
        [JsonIgnore]
        public bool IsNotDefaultSendToAddress => SupplierNameAddress?.Id != SendToAddress?.Id;
        [JsonIgnore]
        public bool IsNotDefaultSendToAttentionName => SupplierMainContact?.Key != SendToAttentionName?.Key;
    }
}
