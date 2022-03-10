using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Debtors
{
    public class DebtorData
    {
        public bool HasError => !string.IsNullOrWhiteSpace(ErrorMessage);
        public string ErrorMessage { get; set; }

        public int NameId { get; set; }
        public string FormattedName { get; set; }
        public string FormattedNameWithCode { get; set; }
        public decimal BillPercentage { get; set; }
        public string Currency { get; set; }
        public decimal? BuyExchangeRate { get; set; }
        public decimal? SellExchangeRate { get; set; }
        public int DecimalPlaces { get; set; }
        public int? RoundBilledValues { get; set; }
        public string ReferenceNo { get; set; }
        public string AttentionName { get; set; }
        public string Address { get; set; }
        public decimal TotalCredits { get; set; }
        public string Instructions { get; set; }
        public string TaxCode { get; set; }
        public string TaxDescription { get; set; }
        public decimal? TaxRate { get; set; }

        public int? AddressId { get; set; }
        public int? AttentionNameId { get; set; }

        public int? CaseId { get; set; }
        public string OpenItemNo { get; set; }
        public string EnteredOpenItemNo { get; set; }
        public DateTime? LogDateTimeStamp { get; set; }
        public bool IsMultiCaseAllowed { get; set; }
        public int? BillFormatProfileId { get; set; }
        public int? BillMapProfileId { get; set; }
        public string BillMapProfileDescription { get; set; }

        public decimal? BillingCap { get; set; }
        public DateTime? BillingCapStart { get; set; }
        public DateTime? BillingCapEnd { get; set; }
        public decimal? BilledAmount { get; set; }

        public int? AddressChangeReasonId { get; set; }

        public int? BillToNameId { get; set; }
        public string BillToFormattedName { get; set; }

        public bool HasCopyToDataChanged { get; set; }

        public bool IsOverriddenDebtor { get; set; }
        public bool HasAddressChanged { get; set; }
        public bool HasAttentionNameChanged { get; set; }
        public bool HasReferenceNoChanged { get; set; }

        public bool UseSendBillsTo { get; set; }

        public bool IsStampFeeApplicable { get; set; }
        public int? LanguageId { get; set; }
        public string LanguageDescription { get; set; }
        public ICollection<DebtorCopiesTo> CopiesTos { get; set; } = new Collection<DebtorCopiesTo>();
        public ICollection<DebtorDiscount> Discounts { get; set; } = new Collection<DebtorDiscount>();
        public ICollection<DebtorWarning> Warnings { get; set; } = new Collection<DebtorWarning>();
        public ICollection<DebtorReference> References { get; set; } = new Collection<DebtorReference>();

        public int? OfficeEntityId { get; set; }

        public bool IsClient { get; set; }

        public string NameType { get; set; }

        public string NameTypeDescription { get; set; }

        public bool HasOfficeInEu { get; set; }

        public decimal? TotalWip { get; set; }

        public DebtorRestrictionStatus DebtorRestriction { get; set; }
    }
}