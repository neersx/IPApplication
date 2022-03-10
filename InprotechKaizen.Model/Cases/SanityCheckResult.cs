using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("SANITYCHECKRESULT")]
    public class SanityCheckResult
    {
        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }
       
        [Column("PROCESSID")]
        public int ProcessId { get; set; }
        
        [Column("CASEID")]
        public int CaseId { get; set; }

        [Column("ISWARNING")]
        public bool IsWarning { get; set; }

        [Column("CANOVERRIDE")]
        public bool CanOverride { get; set; }

        [Column("DISPLAYMESSAGE")]
        public string DisplayMessage { get; set; }
        
        public virtual BackgroundProcess.BackgroundProcess BackgroundProcess { get; set; }

        public virtual Case Case { get; set; }

    }
}
