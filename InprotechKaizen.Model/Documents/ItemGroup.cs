using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Documents
{
    [Table("ITEM_GROUP")]
    public class ItemGroup
    {
        [Key]
        [Column("GROUP_CODE", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Code { get; set; }

        [Key]
        [Column("ITEM_ID", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemId { get; set; }
    }
}
