using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Schedules
{
    [Table("UnrecoverableArtefacts")]
    public class UnrecoverableArtefact
    {
        [Key]
        public long Id { get; set; }

        public long ScheduleExecutionId { get; protected set; }

        [ForeignKey("ScheduleExecutionId")]
        public ScheduleExecution ScheduleExecution { get; set; }

        public string Artefact { get; protected set; }

        public DateTime LastUpdated { get; protected set; }

        [Obsolete]
        public UnrecoverableArtefact()
        {
            
        }

        public UnrecoverableArtefact(ScheduleExecution scheduleExecution, string artefacts, DateTime now)
        {
            if (scheduleExecution == null) throw new ArgumentNullException("scheduleExecution");
            if (string.IsNullOrWhiteSpace(artefacts)) throw new ArgumentNullException("artefacts");

            ScheduleExecution = scheduleExecution;
            Artefact = artefacts;
            LastUpdated = now;
        }
    }
}
