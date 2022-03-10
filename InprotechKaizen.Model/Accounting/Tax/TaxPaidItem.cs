using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Tax
{
    [Table("TAXPAIDITEM")]
    public class TaxPaIdItem
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
        [Column("ACCTCREDITORNO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountCreditorId { get; set; }

        [Key]
        [Column("TAXCODE", Order = 4)]
        [StringLength(3)]
        public string TaxCode { get; set; }

        [Required]
        [StringLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [Column("TAXRATE")]
        public decimal? TaxRate { get; set; }

        [Column("TAXABLEAMOUNT")]
        public decimal? TaxableAmount { get; set; }

        [Column("TAXAMOUNT")]
        public decimal? TaxAmount { get; set; }
    }
}
