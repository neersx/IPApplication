using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases.AssignmentRecordal
{
    [Table("ELEMENT")]
    public class Element
    {
        
        [Column("ELEMENTNO")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("ELEMENT")]
        public string Name { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("ELEMENTCODE")]
        public string Code { get; set; }

        [MaxLength(3)]
        [Column("EDITATTRIBUTE")]
        public string EditAttribute { get; set; }

        [Column("ELEMENT_TID")]
        public int? NameTid { get; set; }
    }
}
