using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public class DebitOrCreditNote
    {
        public int DebtorNameId { get; set; }
        public string DebtorName { get; set; }
        public string DebtorNameType { get; set; }
        public string OpenItemNo { get; set; }
        public string EnteredOpenItemNo { get; set; }
        public decimal BillPercentage { get; set; }
        public int Status { get; set; }
        public decimal LocalValue { get; set; }
        public decimal LocalBalance { get; set; }
        public string Currency { get; set; }
        public decimal? ForeignValue { get; set; }
        public decimal? ForeignBalance { get; set; }
        public decimal? ExchangeRate { get; set; }
        public decimal? AreCreditsAvailable { get; set; }
        public bool IsPrinted { get; set; }
        public decimal LocalTakenUp { get; set; }
        public decimal? ForeignTakenUp { get; set; }
        public decimal ItemPreTaxValue { get; set; }
        public decimal LocalTaxAmount { get; set; }
        public decimal? ForeignTaxAmount { get; set; }
        public decimal? ExchangeRateVariance { get; set; }
        public bool IsCreditPayOut { get; set; }
        public DateTime? LogDateTimeStamp { get; set; }

        public ICollection<DebitOrCreditNoteTax> Taxes { get; set; } = new Collection<DebitOrCreditNoteTax>();
        public ICollection<CreditItem> CreditItems { get; set; } = new Collection<CreditItem>();
    }

    public static class DebitOrCreditNoteExtensions
    {
        public static void ReverseSigns(this DebitOrCreditNote item)
        {
            item.LocalValue *= -1;
            item.LocalBalance *= -1;
            item.LocalTaxAmount *= -1;
            item.ForeignTaxAmount *= -1;
            item.ForeignValue *= -1;
            item.ForeignBalance *= -1;
            item.ExchangeRateVariance *= -1;

            foreach (var taxItem in item.Taxes)
                taxItem.ReverseSigns();
        }
    }
}