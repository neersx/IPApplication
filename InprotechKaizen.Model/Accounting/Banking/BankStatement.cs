using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Banking
{
    [Table("BANKSTATEMENT")]
    public class BankStatement
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("STATEMENTNO")]
        public int StatementNo { get; set; }

        [Column("ACCOUNTOWNER")]
        public int AccountOwner { get; set; }

        [Column("BANKNAMENO")]
        public int BankNameNo { get; set; }

        [Column("ACCOUNTSEQUENCENO")]
        public int AccountSequenceNo { get; set; }

        [Column("STATEMENTENDDATE")]
        public DateTime StatementEndDate { get; set; }

        [Column("CLOSINGBALANCE")]
        public decimal ClosingBalance { get; set; }

        [Column("ISRECONCILED")]
        public decimal IsReconciled { get; set; }

        [Required]
        [StringLength(30)]
        [Column("USERID")]
        public string UserId { get; set; }

        [Column("DATECREATED")]
        public DateTime Datecreated { get; set; }

        [Column("OPENINGBALANCE")]
        public decimal OpeningBalance { get; set; }

        [Column("RECONCILEDDATE")]
        public DateTime? ReconciledDate { get; set; }

        [Column("IDENTITYID")]
        public int? IdEntityId { get; set; }

    }
}
