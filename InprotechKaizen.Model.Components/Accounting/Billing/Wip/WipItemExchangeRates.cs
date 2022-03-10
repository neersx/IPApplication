using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public class WipItemExchangeRates
    {
        public decimal DebtorExchangeRate { get; set; }

        public IEnumerable<WipItemExchangeRate> WipItems { get; set; }
    }

    public class WipItemExchangeRate
    {
        public int WipEntityId { get; set; }

        public int WipTransactionId { get; set; }

        public int WipSequenceNo { get; set; }

        public decimal? BillBuyRate { get; set; }

        public decimal? BillSellRate { get; set; }
    }
}