using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYCOLUMNGROUP")]
    public class QueryColumnGroup
    {
        [Key]
        [Column("GROUPID")]
        public int Id { get; set; }

        [Column("CONTEXTID")]
        public int ContextId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("GROUPNAME")]
        public string GroupName { get; set; }

        [Column("GROUPNAME_TID")]
        public int? GroupNameTId { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short DisplaySequence { get; set; }
    }
}
