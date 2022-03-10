using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYCONTEXTCOLUMN")]
    public class QueryContextColumn
    {
        [Key]
        [Column("CONTEXTID", Order = 1)]
        public int ContextId { get; set; }

        [Key]
        [Column("COLUMNID", Order = 2)]
        [ForeignKey("QueryColumn")]
        public int ColumnId { get; set; }

        [Column("GROUPID")]
        [ForeignKey("Group")]
        public int? GroupId { get; set; }

        [MaxLength(50)]
        [Column("USAGE")]
        public string Usage { get; set; }

        [Column("ISMANDATORY")]
        public bool IsMandatory { get; set; }

        [Column("ISSORTONLY")]
        public bool IsSortOnly { get; set; }

        public virtual QueryColumn QueryColumn { get; set; }

        public virtual QueryColumnGroup Group { get; set; }
    }
}
