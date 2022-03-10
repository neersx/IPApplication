using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede.DataMapping
{
    [Table("ENCODEDVALUE")]
    public class EncodedValue
    {
        [Key]
        [Column("CODEID")]
        public int Id { get; set; }

        [Column("SCHEMEID")]
        public short SchemeId { get; set; }

        [Column("STRUCTUREID")]
        public short StructureId { get; set; }

        [MaxLength(50)]
        [Column("CODE")]
        public string Code { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [MaxLength(50)]
        [Column("OUTBOUNDVALUE")]
        public string OutboundValue { get; set; }

        [ForeignKey("SchemeId")]
        public virtual EncodingScheme EncodingScheme { get; set; }

        [ForeignKey("StructureId")]
        public virtual MapStructure MapStructure { get; set; }
    }
}
