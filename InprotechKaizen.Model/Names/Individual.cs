using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("INDIVIDUAL")]
    public class Individual
    {
        public Individual()
        {
        }

        public Individual(int nameId)
        {
            NameId = nameId;
        }

        [Key]
        [Column("NAMENO")]
        public int NameId { get; protected set; }

        [MaxLength(1)]
        [Column("SEX")]
        public string Gender { get; set; }

        [MaxLength(50)]
        [Column("FORMALSALUTATION")]
        public string FormalSalutation { get; set; }

        [MaxLength(50)]
        [Column("CASUALSALUTATION")]
        public string CasualSalutation { get; set; }

        [Required]
        public Name Name { get; protected set; }
    }
}
