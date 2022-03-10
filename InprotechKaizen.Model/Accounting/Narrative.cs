using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("NARRATIVE")]
    public class Narrative
    {
        [Key]
        [Column("NARRATIVENO")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short NarrativeId { get; set; }

        [Required]
        [MaxLength(6)]
        [Column("NARRATIVECODE")]
        public string NarrativeCode { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("NARRATIVETITLE")]
        public string NarrativeTitle { get; set; }

        [Required]
        [Column("NARRATIVETEXT")]
        public string NarrativeText { get; set; }

        [Column("NARRATIVETEXT_TID")]
        public int? NarrativeTextTid { get; set; }

        [Column("NARRATIVETITLE_TID")]
        public int? NarrativeTitleTid { get; set; }
    }
}