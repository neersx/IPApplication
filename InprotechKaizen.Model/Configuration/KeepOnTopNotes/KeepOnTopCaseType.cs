using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Configuration.KeepOnTopNotes
{
    [Table("KOTCASETYPE")]
    public class KeepOnTopCaseType
    {
        [Key]
        [Column("KOTID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int KotTextTypeId { get; set; }

        [Key]
        [MaxLength(1)]
        [Column("CASETYPE", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public string CaseTypeId { get; set; }

        [ForeignKey("CaseTypeId")]
        public virtual CaseType CaseType { get; set; }

        public virtual KeepOnTopTextType KotTextType { get; set; }
    }
}
