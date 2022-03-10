using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("ALIASTYPE")]
    public class NameAliasType
    {
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("ALIASTYPE")]
        [MaxLength(2)]
        public string Code { get; set; }

        [MaxLength(30)]
        [Column("ALIASDESCRIPTION")]
        public string Description { get; set; }

        [Column("ALIASDESCRIPTION_TID")]
        public int? AliasDescriptionTId { get; set; }

        [Column("MUSTBEUNIQUE")]
        public bool? IsUnique { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }
    }
}
