using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases.AssignmentRecordal
{
    [Table("RECORDALELEMENT")]
    public class RecordalElement
    {
        
        [Column("RECORDALELEMENTNO")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int Id { get; set; }

        [Column("RECORDALTYPENO")]
        public int TypeId { get; set; }

        [Column("ElementNo")]
        public int ElementId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("ELEMENTLABEL")]
        public string ElementLabel { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeCode { get; set; }

        [Required]
        [MaxLength(3)]
        [Column("EDITATTRIBUTE")]
        public string EditAttribute { get; set; }

        public virtual Element Element { get; set; }

        public virtual RecordalType RecordalType { get; set; }

        public virtual NameType NameType { get; set; }
    }
}
