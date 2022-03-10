using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.OpenItem
{
    [Table("OPENITEMTAX")]
    public class OpenItemTax
    {
        [Key]
        [Column("ITEMENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemEntityId { get; set; }

        [Key]
        [Column("ITEMTRANSNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemTransactionId { get; set; }

        [Key]
        [Column("ACCTENTITYNO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountEntityId { get; set; }

        [Key]
        [Column("ACCTDEBTORNO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountDebtorId { get; set; }

        [Key]
        [Column("TAXCODE", Order = 4)]
        [StringLength(3)]
        public string TaxCode { get; set; }

        [Column("TAXRATE")]
        public decimal? TaxRate { get; set; }

        [Column("TAXABLEAMOUNT")]
        public decimal? TaxableAmount { get; set; }

        [Column("TAXAMOUNT")]
        public decimal? TaxAmount { get; set; }

        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [Column("STATE")]
        public string State { get; set; }

        [Column("HARMONISED")]
        public bool? IsHarmonised { get; set; }

        [Column("TAXONTAX")]
        public bool? IsTaxOnTax { get; set; }

        [Column("MODIFIED")]
        public bool? IsModified { get; set; }

        [Column("ADJUSTMENT")]
        public decimal? Adjustment { get; set; }

        [Column("FOREIGNTAXABLEAMOUNT")]
        public decimal? ForeignTaxableAmount { get; set; }

        [Column("FOREIGNTAXAMOUNT")]
        public decimal? ForeignTaxAmount { get; set; }

        [Column("CURRENCY")]
        public string Currency { get; set; }
    }
}
