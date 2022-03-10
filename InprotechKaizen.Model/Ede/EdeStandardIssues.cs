using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDESTANDARDISSUE")]
    public class EdeStandardIssues
    {
        [Key]
        [Column("ISSUEID")]
        public int Id { get; set; }

        [MaxLength(10)]
        [Column("ISSUECODE")]
        public string Code { get; set; }

        [Required]
        [MaxLength(254)]
        [Column("SHORTDESCRIPTION")]
        public string ShortDescription { get; set; }

        [MaxLength(3500)]
        [Column("LONGDESCRIPTION")]
        public string LongDescription { get; set; }
    }
}
