using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Integration
{
    [Table("CPAGLOBALIDENTIFIER")]
    public class CpaGlobalIdentifier
    {
        [Key]
        [Column("ID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("INNOGRAPHYID")]
        public string InnographyId { get; set; }

        [Column("CASEID")]
        [ForeignKey("Case")]
        public int CaseId { get; set; }

        [Column("ISACTIVE")]
        public bool IsActive { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastChanged { get; set; }
        
        public virtual Case Case { get; protected set; }
    }
}