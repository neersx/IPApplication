using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMEFAMILY")]
    public class NameFamily
    {
        [Obsolete("For persistence only.")]
        public NameFamily()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public NameFamily(short id, string title, string comments = null)
        {
            Id = id;
            FamilyTitle = title;
            FamilyComments = comments;
        }

        [Key]
        [Column("FAMILYNO")]
        public short Id { get; set; }

        [MaxLength(50)]
        [Column("FAMILYTITLE")]
        public string FamilyTitle { get; set; }

        [MaxLength(254)]
        [Column("FAMILYCOMMENTS")]
        public string FamilyComments { get; set; }

        [Column("FAMILYCOMMENTS_TID")]
        public int? FamilyCommentsTid { get; set; }

        [Column("FAMILYTITLE_TID")]
        public int? FamilyTitleTid { get; set; }
    }
}