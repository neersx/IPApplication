using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Names
{
    [Table("FILESIN")]
    public class FilesIn
    {
        [Key]
        [Column("NAMENO", Order = 0)]
        public int NameId { get; set; }

        [Key]
        [MaxLength(3)]
        [Column("COUNTRYCODE", Order = 1)]
        public string JurisdictionId { get; set; }

        [MaxLength(254)]
        [Column("NOTES")]
        public string Notes { get; set; }
        
        [ForeignKey("NameId")]
        public virtual Name Name { get; set; }
        
        [ForeignKey("JurisdictionId")]
        public virtual Country Jurisdiction { get; set; }
    }
}