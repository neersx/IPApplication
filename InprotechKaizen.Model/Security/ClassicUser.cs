using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [Table("USERS")]
    public class ClassicUser
    {
        [Key]
        [Column("USERID")]
        public string Id { get; protected set; }

        [MaxLength(50)]
        [Column("NAMEOFUSER")]
        public string Name { get; protected set; }

        public virtual User UserIdentity { get; set; }
    }
}