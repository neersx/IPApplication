using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Work
{
    [Table("WIPPAYMENT")]
    public class WipPayment
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
        [Column("WIPSEQNO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short WipSequenceNo { get; set; }

        [Key]
        [Column("HISTORYLINENO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short HistoryLineNo { get; set; }

        [Key]
        [Column("ACCTDEBTORNO", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountDebtorId { get; set; }

        [Key]
        [Column("PAYMENTSEQNO", Order = 5)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short PaymentSequenceNo { get; set; }
    }
}
