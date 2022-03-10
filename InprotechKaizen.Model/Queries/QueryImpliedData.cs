using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYIMPLIEDDATA")]
    public class QueryImpliedData
    {
        [Key]
        [Column("IMPLIEDDATAID")]
        public int Id { get; set; }

        [Column("CONTEXTID")]
        public int ContextId { get; set; }

        [Column("DATAITEMID")]
        public int? DataItemId { get; set; }
    }
}
