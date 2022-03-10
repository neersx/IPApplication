using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Configuration.KeepOnTopNotes
{
    [Table("KOTTEXTTYPE")]
    public class KeepOnTopTextType
    {
        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Required]
        [MaxLength(2)]
        [Column("TEXTTYPE")]
        public string TextTypeId { get; set; }

        [Required]
        [MaxLength(1)]
        [Column("TYPE")]
        public string Type { get; set; }

        [Column("CASEPROGRAM")]
        public bool CaseProgram { get; set; }

        [Column("NAMEPROGRAM")]
        public bool NameProgram { get; set; }

        [Column("TIMEPROGRAM")]
        public bool TimeProgram { get; set; }

        [Column("BILLINGPROGRAM")]
        public bool BillingProgram { get; set; }

        [Column("TASKPLANNERPROGRAM")]
        public bool TaskPlannerProgram { get; set; }

        [Column("PENDING")]
        public bool IsPending { get; set; }

        [Column("REGISTERED")]
        public bool IsRegistered { get; set; }

        [Column("DEAD")]
        public bool IsDead { get; set; }

        [MaxLength(7)]
        [Column("BACKGROUNDCOLOR")]
        public string BackgroundColor { get; set; }

        [ForeignKey("TextTypeId")]
        public virtual TextType TextType { get; set; }

        public virtual ICollection<KeepOnTopCaseType> KotCaseTypes { get; set; } = new Collection<KeepOnTopCaseType>();

        public virtual ICollection<KeepOnTopNameType> KotNameTypes { get; set; } = new Collection<KeepOnTopNameType>();

        public virtual ICollection<KeepOnTopRole> KotRoles { get; set; } = new Collection<KeepOnTopRole>();
    }
}
