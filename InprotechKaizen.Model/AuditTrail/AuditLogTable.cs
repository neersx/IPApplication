using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.AuditTrail
{
    [Table("AUDITLOGTABLES")]
    public class AuditLogTable
    {
        [Key]
        [Column("TABLENAME")]
        public string Name { get; set; }

        [Column("LOGFLAG")]
        public bool IsLoggingRequired { get; set; }
    }
}