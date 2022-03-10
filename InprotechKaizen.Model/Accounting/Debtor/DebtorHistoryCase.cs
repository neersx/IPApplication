using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Debtor
{
    [Table("DEBTORHISTORYCASE")]
    public class DebtorHistoryCase
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
        [Column("HISTORYLINENO", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short HistoryLineNo { get; set; }

        [Key]
        [Column("CASEID", Order = 5)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CaseId { get; set; }

    }
}
