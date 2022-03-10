using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Integration.Schedules
{
    public enum ScheduleState
    {
        Active = 0,
        Expired = 1,
        Purgatory = 2, // no more scheduled runs but not yet expired
        RunNow = 3,
        Paused = 4,
        Disabled = 5
    }

    public enum ScheduleType
    {
        Scheduled = 0,
        OnDemand = 1,
        Retry = 2,
        Continuous = 3
    }

    public class Schedule : ISoftDeleteable
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Schedule()
        {
            StartTimeValue = TimeSpan.Zero.ToString();
            Failures = new Collection<ScheduleFailure>();
            Executions = new Collection<ScheduleExecution>();
            Type = ScheduleType.Scheduled;
        }

        public int Id { get; set; }

        [Required]
        public string Name { get; set; }

        [Required]
        public DataSourceType DataSourceType { get; set; }

        [Required]
        public DownloadType DownloadType { get; set; }

        public string RunOnDays { get; set; }

        [Required]
        [Column("StartTime")]
        public string StartTimeValue { get; protected set; }

        [NotMapped]
        public TimeSpan StartTime
        {
            get { return TimeSpan.Parse(StartTimeValue); }
            set { StartTimeValue = value.ToString(); }
        }

        [Required]
        public DateTime CreatedOn { get; set; }

        [Required]
        public int CreatedBy { get; set; }

        public DateTime? LastRunStartOn { get; set; }

        public DateTime? NextRun { get; set; }

        public string ExtendedSettings { get; set; }

        public virtual Collection<ScheduleFailure> Failures { get; set; }

        public virtual Collection<ScheduleExecution> Executions { get; set; }

        public bool IsDeleted { get; set; }

        public DateTime? DeletedOn { get; set; }

        public int? DeletedBy { get; set; }

        public DateTime? ExpiresAfter { get; set; }

        public ScheduleState State { get; set; }

        [ForeignKey("ParentId")]
        public virtual Schedule Parent { get; set; }

        [Column("Parent_Id")]
        public int? ParentId { get; internal set; }

        public ScheduleType Type { get; set; }
    }

    public static class ScheduleExtentions
    {
        static readonly Dictionary<string, DayOfWeek> String2DayOfWeekMap = new Dictionary<string, DayOfWeek>
                                                                            {
                                                                                {"mon", DayOfWeek.Monday},
                                                                                {"tue", DayOfWeek.Tuesday},
                                                                                {"wed", DayOfWeek.Wednesday},
                                                                                {"thu", DayOfWeek.Thursday},
                                                                                {"fri", DayOfWeek.Friday},
                                                                                {"sat", DayOfWeek.Saturday},
                                                                                {"sun", DayOfWeek.Sunday},
                                                                            };

        public static IEnumerable<DayOfWeek> GetRunDaysOfWeek(this Schedule schedule)
        {
            return schedule.RunOnDays.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                           .Select(s => String2DayOfWeekMap[s.Trim().ToLower()]);
        }

        public static dynamic GetExtendedSettings(this Schedule schedule)
        {
            return string.IsNullOrWhiteSpace(schedule.ExtendedSettings)
                ? null
                : JsonConvert.DeserializeObject(schedule.ExtendedSettings);
        }

        public static T GetExtendedSettings<T>(this Schedule schedule)
        {
            return string.IsNullOrWhiteSpace(schedule.ExtendedSettings)
                ? default(T)
                : JsonConvert.DeserializeObject<T>(schedule.ExtendedSettings);
        }

        public static bool IsRunOnce(this Schedule schedule)
        {
            return string.IsNullOrWhiteSpace(schedule.RunOnDays);
        }

        public static bool IsRunNow(this Schedule schedule)
        {
            return schedule.Parent != null;
        }
    }
}