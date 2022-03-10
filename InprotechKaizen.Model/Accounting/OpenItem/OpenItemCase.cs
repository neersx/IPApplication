using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.OpenItem
{
    [Table("OPENITEMCASE")]
    public class OpenItemCase
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
        [Column("CASEID", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CaseId { get; set; }

        [Column("STATUS", TypeName = "numeric")]
        public TransactionStatus Status { get; set; }

        [Column("LOCALVALUE")]
        public decimal? LocalValue { get; set; }
        
        [Column("LOCALBALANCE")]
        public decimal? LocalBalance { get; set; }
    }
}
