using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMEMARGINPROFILE")]
    public class NameMarginProfile
    {
        [Key]
        [Column("NAMENO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int NameId { get; set; }

        [Key]
        [Column("NAMEMARGINSEQNO", Order = 1)]
        public Byte NameMarginSeqNo { get; set; }

        [Required]
        [StringLength(3)]
        [Column("CATEGORYCODE")]
        public string CategoryCode { get; set; }

        [Column("MARGINPROFILENO")]
        public int? MarginProfileNo { get; set; }
    }
}