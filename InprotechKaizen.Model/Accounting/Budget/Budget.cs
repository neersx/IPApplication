using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Budget
{
    [Table("BUDGET")]
    public class Budget
    {
        [Key]
        [Column("ENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityNo { get; set; }

        [Key]
        [Column("PROFITCENTRECODE", Order = 1)]
        [StringLength(6)]
        public string ProfitCentreCode { get; set; }

        [Key]
        [Column("LEDGERACCOUNTID", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int LedgerAccountId { get; set; }

        [Key]
        [Column("PERIODID", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int PeriodId { get; set; }
    }
}
