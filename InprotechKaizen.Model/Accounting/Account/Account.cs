using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Account
{
    [Table("ACCOUNT")]
    public class Account
    {
        [Key]
        [Column("ENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityId { get; set; }

        [Key]
        [Column("NAMENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int NameId { get; set; }

        [Column("BALANCE")]
        public decimal? Balance { get; set; }

        [Column("CRBALANCE")]
        public decimal? CreditBalance { get; set; }
    }
}