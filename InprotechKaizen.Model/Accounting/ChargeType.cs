using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Accounting
{
    [Table("CHARGETYPE")]
    public class ChargeType
    {
        [Obsolete("For persistence only.")]
        public ChargeType()
        {
        }

        [Key]
        [Column("CHARGETYPENO", Order = 1)]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("CHARGEDESC")]
        public string Description { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("USEDASFLAG")]
        public short? UsedAsFlag { get; set; }

        [Column("CHARGEDESC_TID")]
        public int? DescriptionTId { get; set; }

        [Column("CHARGEDUEEVENT")]
        public int? ChargeDueEventId { get; set; }

        [Column("CHARGEINCURREDEVENT")]
        public int? ChargeIncurredEventId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("PUBLICFLAG")]
        public bool? PublicFlag { get; set; }
    }
}