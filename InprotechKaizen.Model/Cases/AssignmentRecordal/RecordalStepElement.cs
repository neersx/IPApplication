using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases.AssignmentRecordal
{
    [Table("RECORDALSTEPELEMENT")]
    public class RecordalStepElement
    {
        [Key]
        [Column("CASEID", Order = 0)]
        public int CaseId { get; set; }

        [Key]
        [Column("RECORDALSTEPSEQ", Order = 1)]
        public int RecordalStepId { get; set; }

        [Key]
        [Column("ELEMENTNO", Order = 2)]
        public int ElementId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("ELEMENTLABEL")]
        public string ElementLabel { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeCode { get; set; }

        [MaxLength(3)]
        [Column("EDITATTRIBUTE")]
        public string EditAttribute { get; set; }

        [Column("ELEMENTVALUE")]
        public string ElementValue { get; set; }

        [MaxLength(50)]
        [Column("OTHERVALUE")]
        public string OtherValue { get; set; }

        public virtual Element Element { get; set; }

        public virtual NameType NameType { get; set; }
    }
}
