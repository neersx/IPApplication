
using System;

namespace InprotechKaizen.Model.Components.Names.TrustAccounting
{
    public class TrustAccountingDetails
    {
        public int TraderId { get; set; }
        public string Trader { get; set; }
        public string TraderFull { get; set; }
        public DateTime Date { get; set; }
        public string ItemRefNo { get; set; }
        public int ReferenceNo { get; set; }
        public decimal? LocalValue { get; set; }
        public decimal? LocalBalance { get; set; }
        public decimal? ForeignValue { get; set; }
        public decimal? ForeignBalance { get; set; }
        public decimal? ExchVariance { get; set; }
        public string LocalCurrency { get; set; }
        public string Currency { get; set; }
        public string TransType { get; set; }
        public string Description { get; set; }
        public string DescriptionFull { get; set; }
    }
}