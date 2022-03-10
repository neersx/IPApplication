using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Schedules
{
    [Table("ProcessIdsToCleanup")]
    public class ProcessIdsToCleanup
    {
        [Obsolete("Serialization")]
        public ProcessIdsToCleanup()
        {
        }

        public ProcessIdsToCleanup(int scheduleId, long processId, DateTime addedOn)
        {
            ScheduleId = scheduleId;
            ProcessId = processId;
            AddedOn = addedOn;
        }

        [Key]
        [Column("ScheduleId", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ScheduleId { get; set; }

        [Column("ProcessId")]
        public long ProcessId { get; set; }

        [Column("IsCleanedUp")]
        public bool IsCleanedUp { get; internal set; }

        [Column("AddedOn")]
        public DateTime AddedOn { get; internal set; }

        [Column("CleanupCompletedOn")]
        public DateTime? CleanupCompletedOn { get; internal set; }

        public void MarkAsCleanedup(DateTime cleanedOn)
        {
            CleanupCompletedOn = cleanedOn;
            IsCleanedUp = true;
        }
    }
}