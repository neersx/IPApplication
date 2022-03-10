using System;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public class CreditItem
    {
        public int BestFitScore { get; set; }
        public int ItemEntityId { get; set; }
        public int ItemTransactionId { get; set; }
        public int AccountEntityId { get; set; }
        public int AccountDebtorId { get; set; }
        public string OpenItemNo { get; set; }
        public DateTime ItemDate { get; set; }
        public decimal LocalBalance { get; set; }
        public decimal LocalBalanceOriginal { get; set; }
        public decimal LocalSelected { get; set; }
        public string Currency { get; set; }
        public decimal? ExchangeRate { get; set; }
        public decimal? ForeignBalance { get; set; }
        public decimal? ForeignBalanceOriginal { get; set; }
        public decimal? ForeignSelected { get; set; }
        public bool IsForcedPayOut { get; set; }
        public string ReferenceText { get; set; }
        public string CaseRef { get; set; }
        public int? CaseId { get; set; }
        public int? ItemType { get; set; }
        public string PayPropertyTypeKey { get; set; }
        public string PayPropertyName { get; set; }
        public string PayForWip { get; set; }
        public bool IsLocked { get; set; }
    }
}