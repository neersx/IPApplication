using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.SqlTypes;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYCONTENT")]
    public class QueryContent
    {
        [Key]
        [Column("CONTENTID", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ContentId { get; set; }

        [Column("PRESENTATIONID")]
        [ForeignKey("Presentation")]
        public int PresentationId { get; set; }

        [Column("COLUMNID")]
        public int ColumnId { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short? DisplaySequence { get; set; }

        [Column("SORTORDER")]
        public short? SortOrder { get; set; }

        [MaxLength(1)]
        [Column("SORTDIRECTION")]
        public string SortDirection { get; set; }

        [Column("CONTEXTID")]
        public int ContextId { get; set; }

        [MaxLength(254)]
        [Column("TITLE")]
        public string Title { get; set; }

        [Column("TITLE_TID")]
        public int? TitleTid { get; set; }

        [Column("ISMANDATORY")]
        public SqlByte? IsMandatory { get; set; }

        [Column("GROUPBYSEQUENCE")]
        public short? GroupBySequence { get; set; }

        [MaxLength(1)]
        [Column("GROUPBYSORTDIR")]
        public string GroupBySortDir { get; set; }
        
        public virtual QueryPresentation Presentation { get; set; }

        //// Ensure ICollection property added in parent class
        //public virtual QueryContextColumn Querycontextcolumn { get; set; }
    }
}
