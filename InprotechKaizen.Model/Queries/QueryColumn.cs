using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYCOLUMN")]
    public class QueryColumn
    {
        [Key]
        [Column("COLUMNID", Order = 1)]
        public int ColumnId { get; set; }

        [Column("DATAITEMID")]
        public int DataItemId { get; set; }

        [MaxLength(20)]
        [Column("QUALIFIER")]
        public string Qualifier { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("COLUMNLABEL")]
        public string ColumnLabel { get; set; }

        [Column("COLUMNLABEL_TID")]
        public int? ColumnLabelTid { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTid { get; set; }

        [Column("DOCITEMID")]
        public int? DocItemId { get; set; }
    }
}
