using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Configuration.KeepOnTopNotes
{
    [Table("KOTROLE")]
    public class KeepOnTopRole
    {
        [Key]
        [Column("KOTID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int KotTextTypeId { get; set; }

        [Key]
        [Column("ROLEID", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int RoleId { get; set; }

        [ForeignKey("RoleId")]
        public virtual Role Role { get; set; }

        public virtual KeepOnTopTextType KotTextType { get; set; }
    }
}
