using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Cost
{
    [Table("COSTTRACK")]
    public class CostTrack
    {
        
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("COSTID")]
        public int CostId { get; set; }

        [Column("AGENTNO")]
        public int? AgentNo { get; set; }

    }
}
