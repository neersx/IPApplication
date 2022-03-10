using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using Inprotech.Integration.Documents;

namespace Inprotech.Integration.Schedules
{
    [Table("ScheduleRecoverables")]
    public class ScheduleRecoverable
    {
        [Key]
        public long Id { get; set; }

        public long ScheduleExecutionId { get; internal set; }

        public int? CaseId { get; internal set; }

        public int? DocumentId { get; internal set; }

        [Required]
        [ForeignKey("ScheduleExecutionId")]
        public virtual ScheduleExecution ScheduleExecution { get; set; }

        [ForeignKey("CaseId")]
        public virtual Case Case { get; set; }

        [ForeignKey("DocumentId")]
        public virtual Document Document { get; set; }

        [Required]
        public DateTime LastUpdated { get; set; }

        public byte[] Blob { get; set; }

        [Obsolete]
        public ScheduleRecoverable()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ScheduleRecoverable(ScheduleExecution scheduleExecution, DateTime now)
        {
            if (scheduleExecution == null) throw new ArgumentNullException("scheduleExecution");
            ScheduleExecution = scheduleExecution;
            LastUpdated = now;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ScheduleRecoverable(ScheduleExecution scheduleExecution, Case @case, DateTime now)
        {
            if (scheduleExecution == null) throw new ArgumentNullException("scheduleExecution");
            if (@case == null) throw new ArgumentNullException("case");

            ScheduleExecution = scheduleExecution;
            Case = @case;
            LastUpdated = now;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ScheduleRecoverable(ScheduleExecution scheduleExecution, Document document, DateTime now)
        {
            if (scheduleExecution == null) throw new ArgumentNullException(nameof(scheduleExecution));
            if (document == null) throw new ArgumentNullException(nameof(document));
            
            ScheduleExecution = scheduleExecution;
            Document = document; 
            LastUpdated = now;
        }
    }
}