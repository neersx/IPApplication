using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDEOUTSTANDINGISSUES")]
    public class EdeOutstandingIssues
    {
        [Key]
        [Column("OUTSTANDINGISSUEID")]
        public int Id { get; set; }

        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [MaxLength(50)]
        [Column("TRANSACTIONIDENTIFIER")]
        public string TransactionIdentifier { get; set; }

        [MaxLength(254)]
        [Column("ISSUETEXT")]
        public string Issue { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }

        public virtual EdeStandardIssues StandardIssue { get; set; }
    }
}
