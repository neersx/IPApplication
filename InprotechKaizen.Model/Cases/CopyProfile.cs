using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("COPYPROFILE")]
    public class CopyProfile
    {
        [Obsolete("For persistence only.")]
        public CopyProfile()
        {
        }

        public CopyProfile(string profileName, int sequence)
        {
            ProfileName = profileName;
            Sequence = sequence;
        }

        [Key]
        [MaxLength(50)]
        [Column("PROFILENAME", Order = 0)]
        public string ProfileName { get; protected set; }

        [Key]
        [Column("SEQUENCE", Order = 1)]
        public int Sequence { get; protected set; }

        [Required]
        [MaxLength(30)]
        [Column("COPYAREA")]
        public string CopyArea { get; protected set; }

        [Column("PROFILENAME_TID")]
        public int? ProfileNameTId { get; set; }

        [Column("CRMONLY")]
        public bool CrmOnly { get; set; }
    }
}