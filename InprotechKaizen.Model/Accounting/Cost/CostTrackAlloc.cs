using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Cost
{
    [Table("COSTTRACKALLOC")]
    public class CostTrackAlloc
    {
        [Key]
        [Column("COSTID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CostId { get; set; }

        [Key]
        [Column("COSTALLOCNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short CostAllocNo { get; set; }
        
        [Column("DEBTORNO")]
        public int DebtorNo { get; set; }
        
        [Column("DIVISIONNO")]
        public int? DivisionNo { get; set; }
    }
}
