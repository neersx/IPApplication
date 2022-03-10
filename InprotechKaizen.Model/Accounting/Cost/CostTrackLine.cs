using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Cost
{
    [Table("COSTTRACKLINE")]
    public class CostTrackLine
    {
        [Key]
        [Column("COSTID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CostId { get; set; }

        [Key]
        [Column("COSTLINENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short CostLineNo { get; set; }

        [Column("FOREIGNAGENTNO")]
        public int? ForeignAgentNo { get; set; }

        [Column("DIVISIONNO")]
        public int? DivisionNo { get; set; }

    }
}
