using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede.DataMapping
{
    [Table("MAPSTRUCTURE")]
    public class MapStructure
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public MapStructure()
        {
            Mappings = new HashSet<Mapping>();
            MapScenarios = new HashSet<MapScenario>();
        }

        [Key]
        [Column("STRUCTUREID")]
        public short Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("STRUCTURENAME")]
        public string Name { get; set; }

        [Column("STRUCTURENAME_TID")]
        public int? NameTid { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("TABLENAME")]
        public string TableName { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("KEYCOLUMNAME")]
        public string KeyColumnName { get; set; }

        [MaxLength(30)]
        [Column("CODECOLUMNNAME")]
        public string CodeColumnName { get; set; }

        [MaxLength(30)]
        [Column("DESCCOLUMNNAME")]
        public string DescColumnName { get; set; }
        
        public virtual ICollection<Mapping> Mappings { get; set; }
        
        public virtual ICollection<MapScenario> MapScenarios { get; set; }

        public virtual ICollection<EncodedValue> EncodedValues { get; set; } 
    }
}
