using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Debtor
{
    [Table("DEBITNOTEIMAGE")]
    public class DebitNoteImage
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("RULESEQNO")]
        public int RuleId { get; set; }

        [Column("DEBTORNO")]
        public int? DebtorId { get; set; }
    }
}
