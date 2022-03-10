using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Schedules
{
    public class ScheduleFailure
    {
        [Obsolete("For persistence only.")]
        public ScheduleFailure()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ScheduleFailure(Schedule schedule, ScheduleExecution scheduleExecution, DateTime date, string log)
        {
            if (schedule == null) throw new ArgumentNullException(nameof(schedule));
            
            if (string.IsNullOrWhiteSpace(log)) throw new ArgumentException("A valid log is required");

            ScheduleExecution = scheduleExecution;
            Schedule = schedule.Parent ?? schedule;
            Date = date;
            Log = log;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
           "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ScheduleFailure(Schedule schedule, DateTime date, string log)
            : this(schedule, null, date, log)
        {
            
        }

        public int Id { get; set; }

        [Required]
        public DateTime Date { get; set; }

        [Required]
        public string Log { get; set; }

        [Required]
        public virtual Schedule Schedule { get; set; }

        public long? ScheduleExecutionId { get; set; }

        [ForeignKey("ScheduleExecutionId")]
        public virtual ScheduleExecution ScheduleExecution { get; set; }
    }
}