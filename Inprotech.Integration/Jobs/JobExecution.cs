using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Jobs
{
    [Table("JOBEXECUTIONS")]
    public class JobExecution
    {
        [Key]
        public long Id { get; set; }

        [Column("JobId")]
        public long JobId { get; set; }

        [Required]
        [ForeignKey("JobId")]
        public Job Job { get; set; }

        public Status Status { get; set; }

        public DateTime? Started { get; set; }

        public DateTime? Finished { get; set; }

        public string Error { get; set; }

        public string State { get; set; }
    }
}