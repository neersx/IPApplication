using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("DEBTORSTATUS")]
    public class DebtorStatus
    {
        [Obsolete("For persistence only.")]
        public DebtorStatus()
        {
        }

        public DebtorStatus(short debtorStatusId)
        {
            Id = debtorStatusId;
        }

        [Key]
        [Column("BADDEBTOR")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short Id { get; protected set; }

        [MaxLength(50)]
        [Column("DEBTORSTATUS")]
        public string Status { get; set; }

        [Column("ACTIONFLAG")]
        public decimal? RestrictionType { get; set; }

        [MaxLength(10)]
        [Column("CLEARPASSWORD")]
        public string ClearTextPassword { get; set; }

        [Column("DEBTORSTATUS_TID")]
        public int? StatusTId { get; set; }

        public short RestrictionAction
        {
            get
            {
                if(!RestrictionType.HasValue)
                    return KnownDebtorRestrictions.NoRestriction;

                return Convert.ToInt16(RestrictionType.Value);
            }
        }
    }
}