using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{

    [Table("CURRENCY")]
    public class Currency
    {
        public Currency()
        {

        }
        public Currency(string id)
        {
            Id = id;
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

        [MaxLength(40)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DATECHANGED")]
        public DateTime? DateChanged { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [Column("DECIMALPLACES")]
        public byte? DecimalPlaces { get; set; }

        [Column("ROUNDBILLEDVALUES")]
        public short? RoundBillValues { get; set; }
    }
}