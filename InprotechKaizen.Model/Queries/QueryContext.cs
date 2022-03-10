using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYCONTEXT")]
    public class QueryContextModel
    {
        [Key]
        [Column("CONTEXTID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("CONTEXTNAME")]
        public string Name { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("PROCEDURENAME")]
        public string ProcedureName { get; set; }
    }
}