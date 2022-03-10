using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration.SiteControl
{
    [Table("RELEASEVERSIONS")]
    public class ReleaseVersion
    {
        [Key]
        [Column("VERSIONID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("VERSIONNAME")]
        public string VersionName { get; set; }

        [Column("RELEASEDATE")]
        public DateTime? ReleaseDate { get; set; }

        [Column("SEQUENCE")]
        public int? Sequence{ get; set; }
    }
}
