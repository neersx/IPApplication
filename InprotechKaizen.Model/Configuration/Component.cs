using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("COMPONENTS")]
    public class Component
    {
        [Key]
        [Column("COMPONENTID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("COMPONENTNAME")]
        public string ComponentName { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("INTERNALNAME")]
        public string InternalName { get; set; }

        [Column("COMPONENTNAME_TID")]
        public int? ComponentNameTId { get; set; }
    }
}
