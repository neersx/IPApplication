using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EXTERNALNAMEMAPPING")]
    public class ExternalNameMapping
    {
        [Key]
        [Column("NAMEMAPID")]
        public int Id { get; set; }

        [Column("EXTERNALNAMEID")]
        public int ExternalNameId { get; set; }

        [Column("INPRONAMENO")]
        public int InproNameId { get; set; }
        
        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyType { get; set; }

        [Column("INSTRUCTORNAMENO")]
        public int? InstructorNameId { get; set; }
    }
}
