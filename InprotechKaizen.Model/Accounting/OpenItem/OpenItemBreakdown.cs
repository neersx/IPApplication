using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.OpenItem
{
    [Table("OPENITEMBREAKDOWN")]
    public class OpenItemBreakdown
    {
        [Key]
        [Column("BREAKDOWNID")]
        public int BreakDownId { get; set; }

        [Column("ACCTDEBTORNO")]
        public int AccountDebtorId { get; set; }

    }
}
