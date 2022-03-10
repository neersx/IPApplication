using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede.DataMapping
{
    [Table("MAPSCENARIO")]
    public class MapScenario
    {
        [Key]
        [Column("SCENARIOID")]
        public int Id { get; set; }

        [Column("SYSTEMID")]
        public short SystemId { get; set; }

        [Column("STRUCTUREID")]
        public short StructureId { get; set; }

        [Column("SCHEMEID")]
        public short? SchemeId { get; set; }

        [Column("IGNOREUNMAPPED")]
        public bool IgnoreUnmapped { get; set; }

        [ForeignKey("SchemeId")]
        public virtual EncodingScheme EncodingScheme { get; set; }

        [ForeignKey("SystemId")]
        public virtual ExternalSystem ExternalSystem { get; set; }

        [ForeignKey("StructureId")]
        public virtual MapStructure MapStructure { get; set; }
    }
}
