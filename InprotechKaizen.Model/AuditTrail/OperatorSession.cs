using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.AuditTrail
{
    [Table("SESSION")]
    public class OperatorSession
    {
        [Obsolete("For persistence only.")]
        public OperatorSession()
        {
        }

        public OperatorSession(DateTime startDate, string program, int sessionId)
        {
            StartDate = startDate;
            Program = program;
            SessionId = sessionId;
        }

        [Key]
        [Column("SESSIONNO")]
        public int Id { get; protected set; }

        [Column("STARTDATE")]
        public DateTime StartDate { get; protected set; }

        [MaxLength(100)]
        [Column("PROGRAM")]
        public string Program { get; protected set; }

        [Column("SESSIONIDENTIFIER")]
        public int SessionId { get; protected set; }

        public virtual User User { get; protected set; }

        public void SetUser(User user)
        {
            User = user;
        }
    }
}