using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Jobs
{
    public enum JobRecurrence
    {
        Once = 0,
        Hourly = 60,
        EveryMinute = 1,
        EveryFiveMinutes = 5,
        EveryTenMinutes = 10,
        EveryFifteenMinutes = 15,
        EveryThirtyMinutes = 30,
        Daily = 1440,
        Weekly = 10080,
        Fortnightly = 20160
    }

    public enum Status
    {
        None,
        Started,
        Completed,
        Failed
    }

    [Table("JOBS")]
    public class Job
    {
        public Job()
        {
        }

        public Job(string instanceName)
        {
            RunOnInstanceName = instanceName;
        }

        [Key]
        public long Id { get; set; }

        [Required]
        public string Type { get; set; }

        [Required]
        public JobRecurrence Recurrence { get; set; }

        [Required]
        public DateTime NextRun { get; set; }

        public bool IsActive { get; set; }

        public string RunOnInstanceName { get; set; }

        public string JobArguments { get; set; }
    }
}
