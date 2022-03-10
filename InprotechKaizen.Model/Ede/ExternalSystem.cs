using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EXTERNALSYSTEM")]
    public class ExternalSystem
    {
        [Key]
        [Column("SYSTEMID")]
        public short Id { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("SYSTEMNAME")]
        public string Name { get; set; }

        [Required]
        [MaxLength(20)]
        [Column("SYSTEMCODE")]
        public string Code { get; set; }
    }
}
