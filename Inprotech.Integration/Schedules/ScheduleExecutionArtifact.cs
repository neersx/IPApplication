using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Schedules
{
    [Table("ScheduleExecutionArtifacts")]
    public class ScheduleExecutionArtifact
    {
        [Key]
        public long Id { get; set; }

        public long ScheduleExecutionId { get; set; }

        public int? CaseId { get; set; }

        public byte[] Blob { get; set; }
    }
}