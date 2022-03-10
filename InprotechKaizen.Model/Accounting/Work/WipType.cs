using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Work
{
    [Table("WIPTYPE")]
    public class WipType
    {
        [Key]
        [MaxLength(6)]
        [Column("WIPTYPEID")]
        public string Id { get; set; }

        [MaxLength(50)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTid { get; set; }

        [Column("WIPTYPESORT")]
        public short? WipTypeSortOrder { get; set; }

        [MaxLength(3)]
        [Column("CATEGORYCODE")]
        public string CategoryId { get; set; }

        public virtual WipCategory Category { get; set; }
    }
}