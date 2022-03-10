using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases.AssignmentRecordal
{
    [Table("RECORDALTYPE")]
    public class RecordalType
    {

        [Key]
        [Column("RECORDALTYPENO")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("RECORDALTYPE")]
        public string RecordalTypeName { get; set; }

        [Column("REQUESTEVENTNO")]
        public int? RequestEventId { get; set; }

        [MaxLength(2)]
        [Column("REQUESTACTION")]
        public string RequestActionId { get; set; }

        [Column("RECORDEVENTNO")]
        public int? RecordEventId { get; set; }

        [MaxLength(2)]
        [Column("RECORDACTION")]
        public string RecordActionId { get; set; }

        public virtual Events.Event RequestEvent { get; set; }

        public virtual Events.Event RecordEvent { get; set; }

        public virtual Action RequestAction { get; set; }

        public virtual Action RecordAction { get; set; }
    }
}
