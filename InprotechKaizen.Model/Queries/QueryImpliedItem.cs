using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYIMPLIEDITEM")]
    public class QueryImpliedItem
    {
        [Key]
        [Column("IMPLIEDDATAID", Order = 1)]
        public int Id { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 2)]
        public short SequenceNo { get; set; }

        [MaxLength(50)]
        [Column("USAGE")]
        public string Usage { get; set; }
        
        [Required]
        [MaxLength(50)]
        [Column("PROCEDUREITEMID")]
        public string ProcedureItemId { get; set; }
    }
}
