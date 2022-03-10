using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede.DataMapping
{

    [Table("ENCODINGSTRUCTURE")]
    public class EncodingStructure
    {
        [Key]
        [Column("SCHEMEID", Order = 1)]
        public short SchemeId { get; set; }

        [Key]
        [Column("STRUCTUREID", Order = 2)]
        public short StructureId { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("NAME")]
        public string Name { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }
    }
}
