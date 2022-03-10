using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [Table("IDENTITYNAMES")]
    public class IdentityNames
    {
        [Key]
        [Column("IDENTITYID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int IdentityId { get; set; }

        [Key]
        [Column("NAMENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int NameId { get; set; }

        [MaxLength(30)]
        [Column("ADMINISTRATOR")]
        public string Administrator { get; set; }
    }
}