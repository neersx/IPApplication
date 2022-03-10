using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Billing
{
    [Table("BILLEDITEM")]
    public class BilledItem
    {
        [Key]
        [Column("ENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityId { get; set; }

        [Key]
        [Column("TRANSNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionId { get; set; }

        [Key]
        [Column("WIPENTITYNO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int WipEntityId { get; set; }

        [Key]
        [Column("WIPTRANSNO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int WipTransactionId { get; set; }

        [Key]
        [Column("WIPSEQNO", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short WipSequenceNo { get; set; }

        [Column("BILLEDVALUE")]
        public decimal? BilledValue { get; set; }

        [Column("ADJUSTEDVALUE")]
        public decimal? AdjustedValue { get; set; }

        [Column("REASONCODE")]
        public string ReasonCode { get; set; }

        [Column("ITEMENTITYNO")]
        public int? ItemEntityId { get; set; }

        [Column("ITEMTRANSNO")]
        public int? ItemTransactionId { get; set; }

        [Column("ITEMLINENO")]
        public short? ItemLineNo { get; set; }

        [Column("ACCTENTITYNO")]
        public int? AccountEntityId { get; set; }

        [Column("ACCTDEBTORNO")]
        public int? AccountDebtorId { get; set; }

        [Column("FOREIGNCURRENCY")]
        public string ForeignCurrency { get; set; }

        [Column("FOREIGNBILLEDVALUE")]
        public decimal? ForeignBilledValue { get; set; }

        [Column("FOREIGNADJUSTEDVALUE")]
        public decimal? ForeignAdjustedValue { get; set; }

        [Column("GENERATEDFROMTAXCODE")]
        public string GeneratedFromTaxCode { get; set; }
    }
}
