using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CPAUPDATE")]
    public class CpaUpdate
    {
        [Key]
        [Column("ROWID")]
        public int RowId { get; set; }

        [Column("NAMEID")]
        public int? NameId { get; set; }
    }
}