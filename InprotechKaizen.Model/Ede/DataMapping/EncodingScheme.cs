using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Ede.DataMapping
{
    [Table("ENCODINGSCHEME")]
    public class EncodingScheme
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public EncodingScheme()
        {
            MapScenarios = new HashSet<MapScenario>();
        }

        [Key]
        [Column("SCHEMEID")]
        public short Id { get; set; }

        [Required]
        [MaxLength(20)]
        [Column("SCHEMECODE")]
        public string Code { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("SCHEMENAME")]
        public string Name { get; set; }

        [MaxLength(254)]
        [Column("SCHEMEDESCRIPTION")]
        public string Description { get; set; }

        [Column("ISPROTECTED")]
        public bool IsProtected { get; set; }

        public virtual ICollection<MapScenario> MapScenarios { get; set; }
    }
}