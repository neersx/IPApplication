namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public class DebitOrCreditNoteTax
    {
        public string OpenItemNo { get; set; }
        public int DebtorNameId { get; set; }
        public string TaxCode { get; set; }
        public string TaxDescription { get; set; }
        public decimal? TaxRate { get; set; }
        public decimal TaxableAmount { get; set; }
        public decimal TaxAmount { get; set; }
        public decimal? ForeignTaxableAmount { get; set; }
        public decimal? ForeignTaxAmount { get; set; }
        public string Currency { get; set; }
    }

    public static class DebitOrCreditNoteTaxExtensions
    {
        public static void ReverseSigns(this DebitOrCreditNoteTax taxItem)
        {
            taxItem.TaxAmount *= -1;
            taxItem.TaxableAmount *= -1;
            taxItem.ForeignTaxableAmount *= -1;
            taxItem.ForeignTaxAmount *= -1;
        }
    }
}