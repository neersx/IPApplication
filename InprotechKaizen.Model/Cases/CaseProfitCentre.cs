using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASEPROFITCENTRE")]
    public class CaseProfitCentre
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("SEQUENCENO")]
        public short SequenceNo { get; set; }

        [Column("INSTRUCTOR")]
        public int? Instructor { get; set; }
    }
}
