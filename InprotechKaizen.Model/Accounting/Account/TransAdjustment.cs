using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Account
{
    [Table("TRANSADJUSTMENT")]
    public class TransAdjustment
    {
        [Key]
        [Column("ENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityId { get; set; }

        [Key]
        [Column("TRANSNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionId { get; set; }

        [Column("TOEMPLOYEENO")]
        public int? ToStaffId { get; set; }

        [Column("TOACCTNAMENO")]
        public int? ToAccountNameId { get; set; }
    }
}