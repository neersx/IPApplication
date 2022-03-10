using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMELANGUAGE")]
    public class NameLanguage
    {
        [Key]
        [Column("NAMENO", Order = 1)]
        public int NameId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 2)]
        public short Sequence { get; set; }

        [Column("LANGUAGE")]
        public int LanguageId { get; set; }

        [MaxLength(2)]
        [Column("ACTION")]
        public string ActionId { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }
    }
}