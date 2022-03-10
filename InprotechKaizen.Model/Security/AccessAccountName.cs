using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [Table("ACCESSACCOUNTNAMES")]
    public class AccessAccountName
    {
        [Key]
        [Column("ACCOUNTID", Order = 1)]
        public int AccessAccountId { get; set; }

        [Key]
        [Column("NAMENO", Order = 2)]
        public int NameId { get; set; }
    }
}