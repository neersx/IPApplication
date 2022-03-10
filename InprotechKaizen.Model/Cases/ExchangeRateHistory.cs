using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("EXCHANGERATEHIST")]
    public class ExchangeRateHistory
    {
        public ExchangeRateHistory()
        {

        }
        public ExchangeRateHistory(Currency currency)
        {
            Id = currency.Id;
            BankRate = currency.BankRate;
            BuyRate = currency.BuyRate;
            SellFactor = currency.SellFactor;
            BuyFactor = currency.BuyFactor;
            SellRate = currency.SellRate;
            if (currency.DateChanged != null) DateChanged = currency.DateChanged.Value;
        }

        [Key]
        [MaxLength(3)]
        [Column("CURRENCY", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public string Id { get; set; }

        [Column("BANKRATE")]
        public decimal? BankRate { get; set; }

        [Column("SELLRATE")]
        public decimal? SellRate { get; set; }

        [Column("BUYRate")]
        public decimal? BuyRate { get; set; }

        [Column("BUYFACTOR")]
        public decimal? BuyFactor { get; set; }

        [Column("SELLFACTOR")]
        public decimal? SellFactor { get; set; }

        [Column("DATEEFFECTIVE")]
        public DateTime DateChanged { get; set; }

    }
}
