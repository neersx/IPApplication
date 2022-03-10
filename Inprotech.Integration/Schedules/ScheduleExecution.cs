using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Schedules
{
    public enum ScheduleExecutionStatus
    {
        Started = 0,
        Complete = 1,
        Failed = 2,
        Cancelling = 3,
        Cancelled = 4
    }

    [Table("ScheduleExecutions")]
    public class ScheduleExecution
    {
        [Key]
        public long Id { get; set; }

        [Column("ScheduleId")]
        public int ScheduleId { get; internal set; }

        [ForeignKey("ScheduleId")]
        public virtual Schedule Schedule { get; set; }

        [Required]
        public Guid SessionGuid { get; set; }

        public string CorrelationId { get; set; }

        public DateTime Started { get; set; }

        public DateTime? Finished { get; set; }

        public int? CasesIncluded { get; set; }

        public int? CasesProcessed { get; set; }

        public int? DocumentsIncluded { get; set; }

        public int? DocumentsProcessed { get; set; }

        [Required]
        public DateTime UpdatedOn { get; set; }

        public string AdditionalData { get; set; }

        public bool IsTidiedUp { get; set; }

        [Required]
        public ScheduleExecutionStatus Status { get; set; }

        public string CancellationData { get; set; }

        [Obsolete("Serialisation")]
        public ScheduleExecution()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ScheduleExecution(Guid sessionGuid, Schedule schedule, DateTime started, string correlationId = null)
        {
            if (schedule == null) throw new ArgumentNullException(nameof(schedule));

            SessionGuid = sessionGuid;
            Schedule = schedule;
            ScheduleId = schedule.Id;
            Started = started;
            CorrelationId = correlationId;
            UpdatedOn = started;
        }
    }
}
