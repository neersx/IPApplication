using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Banking
{
    [Table("STATEMENTTRANS")]
    public class StatementTran
    {
        [Key]
        [Column("STATEMENTNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int StatementNo { get; set; }

        [Key]
        [Column("ACCOUNTOWNER", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountOwner { get; set; }

        [Key]
        [Column("BANKNAMENO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int BankNameNo { get; set; }

        [Key]
        [Column("ACCOUNTSEQUENCENO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountSequenceNo { get; set; }

        [Key]
        [Column("HISTORYLINENO", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int HistoryLineNo { get; set; }

    }
}
