using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Documents
{
    [Table("ITEM_NOTE")]
    public class ItemNote
    {
        [Key]
        [Column("ITEM_ID")]
        [ForeignKey("Item")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemId { get; set; }

        [Column("ITEM_NOTES")]
        public string ItemNotes { get; set; }

        public virtual DocItem Item { get; set; }

    }
}
